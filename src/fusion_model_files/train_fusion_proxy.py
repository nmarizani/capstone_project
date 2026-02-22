from __future__ import annotations
import argparse
import os
from typing import Dict, List
import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold
from src.fusion_model_files.utils import ensure_dir, pick_threshold_for_recall, save_json, timestamp_version


def build_feature_matrix(df: pd.DataFrame, include_risk_level: bool = False) -> tuple[pd.DataFrame, np.ndarray]:
    target = "pph_proxy_v1"
    if target not in df.columns:
        raise ValueError("Expected target column 'pph_proxy_v1' in input CSV.")

    drop_cols = {
        target,
        "pph_proxy_score_v1",
        "pph_proxy_label_type",
        "pph",  # if present later
        "Label",
        "anaemic",
        "Anaemic",
    }
    if not include_risk_level:
        drop_cols.add("Risk Level")

    X_df = df.drop(columns=[c for c in drop_cols if c in df.columns], errors="ignore").copy()

    # Keep numeric only
    X_df = X_df.select_dtypes(include=[np.number]).copy()
    X_df = X_df.replace([np.inf, -np.inf], np.nan)
    X_df = X_df.fillna(X_df.median(numeric_only=True))

    y = df[target].astype(int).values
    return X_df, y


def train_xgb_oof_calibrated(X: np.ndarray, y: np.ndarray, random_state: int = 42, n_splits: int = 5) -> dict:
    skf = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=random_state)
    oof_base = np.zeros(len(y), dtype=float)
    fold_stats = []

    pos = int(y.sum())
    neg = int(len(y) - pos)
    spw = float(neg / max(pos, 1))

    for fold, (tr, te) in enumerate(skf.split(X, y), start=1):
        model = xgb.XGBClassifier(
            n_estimators=500,
            max_depth=4,
            learning_rate=0.03,
            subsample=0.9,
            colsample_bytree=0.9,
            reg_lambda=1.0,
            gamma=0.0,
            min_child_weight=2,
            scale_pos_weight=spw,
            eval_metric="logloss",
            random_state=random_state + fold,
            n_jobs=-1,
        )
        model.fit(X[tr], y[tr])

        p = model.predict_proba(X[te])[:, 1]
        oof_base[te] = p

        # Fold metrics (guard ROC-AUC on edge case)
        fold_pr = float(average_precision_score(y[te], p))
        fold_roc = float(roc_auc_score(y[te], p)) if len(np.unique(y[te])) > 1 else None
        fold_stats.append({"fold": fold, "pr_auc": fold_pr, "roc_auc": fold_roc})
        print(f"[Fold {fold}] PR-AUC={fold_pr:.4f} ROC-AUC={fold_roc if fold_roc is not None else 'NA'}")

    # Platt calibrator on OOF predictions
    calibrator = LogisticRegression(solver="lbfgs", max_iter=1000)
    calibrator.fit(oof_base.reshape(-1, 1), y)
    oof_cal = calibrator.predict_proba(oof_base.reshape(-1, 1))[:, 1]

    threshold = pick_threshold_for_recall(y, oof_cal, min_recall=0.90)
    y_pred = (oof_cal >= threshold).astype(int)

    metrics = {
        "roc_auc_oof_cal": float(roc_auc_score(y, oof_cal)) if len(np.unique(y)) > 1 else None,
        "pr_auc_oof_cal": float(average_precision_score(y, oof_cal)),
        "threshold": float(threshold),
        "recall_oof": float(recall_score(y, y_pred, zero_division=0)),
        "precision_oof": float(precision_score(y, y_pred, zero_division=0)),
        "f1_oof": float(f1_score(y, y_pred, zero_division=0)),
        "positive_rate": float(y.mean()),
        "fold_stats": fold_stats,
        "confusion_matrix_oof": confusion_matrix(y, y_pred).tolist(),
        "classification_report_oof": classification_report(y, y_pred, zero_division=0, output_dict=True),
        "scale_pos_weight": spw,
    }

    # Final model trained on all data
    final_model = xgb.XGBClassifier(
        n_estimators=500,
        max_depth=4,
        learning_rate=0.03,
        subsample=0.9,
        colsample_bytree=0.9,
        reg_lambda=1.0,
        gamma=0.0,
        min_child_weight=2,
        scale_pos_weight=spw,
        eval_metric="logloss",
        random_state=random_state,
        n_jobs=-1,
    )
    final_model.fit(X, y)

    return {
        "final_model": final_model,
        "calibrator": calibrator,
        "oof_base": oof_base,
        "oof_cal": oof_cal,
        "metrics": metrics,
    }


def save_eval_plots(y: np.ndarray, y_prob: np.ndarray, y_pred: np.ndarray, out_dir: str):
    try:
        import matplotlib.pyplot as plt
        from sklearn.metrics import precision_recall_curve, roc_curve, auc

        fig_dir = ensure_dir("reports/figures/fusion")

        # ROC
        fpr, tpr, _ = roc_curve(y, y_prob)
        roc_auc = auc(fpr, tpr)
        plt.figure(figsize=(6, 4))
        plt.plot(fpr, tpr, label=f"AUC={roc_auc:.3f}")
        plt.plot([0, 1], [0, 1], "k--", alpha=0.5)
        plt.xlabel("FPR")
        plt.ylabel("TPR")
        plt.title("Fusion Proxy Model ROC (OOF Calibrated)")
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(fig_dir, "fusion_proxy_roc_oof.png"), dpi=150)
        plt.close()

        # PR
        p, r, _ = precision_recall_curve(y, y_prob)
        pr_auc = auc(r, p)
        plt.figure(figsize=(6, 4))
        plt.plot(r, p, label=f"AUC={pr_auc:.3f}")
        plt.xlabel("Recall")
        plt.ylabel("Precision")
        plt.title("Fusion Proxy Model PR Curve (OOF Calibrated)")
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(fig_dir, "fusion_proxy_pr_oof.png"), dpi=150)
        plt.close()

        # Prediction distribution
        plt.figure(figsize=(6, 4))
        plt.hist(y_prob[y == 0], bins=30, alpha=0.7, label="proxy=0")
        plt.hist(y_prob[y == 1], bins=30, alpha=0.7, label="proxy=1")
        plt.xlabel("Calibrated probability")
        plt.ylabel("Count")
        plt.title("Fusion Proxy Probabilities by Class")
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(fig_dir, "fusion_proxy_prob_hist_oof.png"), dpi=150)
        plt.close()

    except Exception as e:
        print("[WARN] Could not save evaluation plots:", e)


def main():
    parser = argparse.ArgumentParser(description="Train proxy-supervised fusion model on pph_proxy_v1.")
    parser.add_argument("--input", default="data/processed/fusion_master_with_embeddings.csv")
    parser.add_argument("--artifacts-root", default="models_artifacts/fusion_pph_proxy")
    parser.add_argument("--include-risk-level", action="store_true", help="Include Risk Level (numeric if present) as feature if available.")
    parser.add_argument("--random-state", type=int, default=42)
    args = parser.parse_args()

    df = pd.read_csv(args.input)

    # If unsupervised fusion embeddings haven't been merged, script still works on base features.
    if "pph_proxy_v1" not in df.columns:
        raise ValueError("Input CSV must contain pph_proxy_v1. Run proxy_rules.py first (and optionally unsupervised fusion trainer after).")

    # Optional encoding of Risk Level if explicitly included
    if args.include_risk_level and "Risk Level" in df.columns and not pd.api.types.is_numeric_dtype(df["Risk Level"]):
        rl = df["Risk Level"].astype(str).str.strip().str.lower().map({"low": 0, "medium": 1, "high": 2})
        df["Risk Level"] = rl

    X_df, y = build_feature_matrix(df, include_risk_level=args.include_risk_level)
    X = X_df.values.astype(np.float32)

    result = train_xgb_oof_calibrated(X, y, random_state=args.random_state, n_splits=5)

    threshold = result["metrics"]["threshold"]
    y_pred_oof = (result["oof_cal"] >= threshold).astype(int)
    save_eval_plots(y, result["oof_cal"], y_pred_oof, args.artifacts_root)

    version = timestamp_version()
    out_dir = ensure_dir(os.path.join(args.artifacts_root, version))

    joblib.dump(result["final_model"], os.path.join(out_dir, "model.pkl"))
    joblib.dump(result["calibrator"], os.path.join(out_dir, "calibrator.pkl"))

    save_json({"threshold": threshold, "target": "pph_proxy_v1", "min_recall": 0.90},
              os.path.join(out_dir, "threshold.json"))
    save_json({"features": X_df.columns.tolist(), "include_risk_level": bool(args.include_risk_level)},
              os.path.join(out_dir, "features.json"))
    save_json(result["metrics"], os.path.join(out_dir, "metrics.json"))

    print("Saved fusion proxy artifacts:", out_dir)
    print("OOF PR-AUC:", result["metrics"]["pr_auc_oof_cal"])
    print("OOF Recall:", result["metrics"]["recall_oof"])
    print("OOF Precision:", result["metrics"]["precision_oof"])


if __name__ == "__main__":
    main()