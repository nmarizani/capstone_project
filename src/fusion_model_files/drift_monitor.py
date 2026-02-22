from __future__ import annotations
import argparse
import os
from typing import Dict, List
import numpy as np
import pandas as pd
from src.fusion_model_files.utils import ensure_dir, save_json


def psi(expected: pd.Series, actual: pd.Series, bins: int = 10, eps: float = 1e-6) -> float:
    e = pd.to_numeric(expected, errors="coerce").dropna().astype(float)
    a = pd.to_numeric(actual, errors="coerce").dropna().astype(float)
    if len(e) < 20 or len(a) < 20:
        return float("nan")

    quantiles = np.linspace(0, 1, bins + 1)
    cuts = np.unique(np.quantile(e, quantiles))
    if len(cuts) < 3:
        return 0.0

    e_counts, _ = np.histogram(e, bins=cuts)
    a_counts, _ = np.histogram(a, bins=cuts)

    e_dist = e_counts / max(e_counts.sum(), 1)
    a_dist = a_counts / max(a_counts.sum(), 1)
    e_dist = np.clip(e_dist, eps, None)
    a_dist = np.clip(a_dist, eps, None)

    return float(np.sum((a_dist - e_dist) * np.log(a_dist / e_dist)))


def embedding_centroid_shift(ref: pd.DataFrame, cur: pd.DataFrame) -> float | None:
    emb_cols = [c for c in ref.columns if c.startswith(("clin_emb_", "anemia_emb_", "ppg_emb_", "fusion_emb_")) and c in cur.columns]
    if not emb_cols:
        return None
    ref_num = ref[emb_cols].apply(pd.to_numeric, errors="coerce").replace([np.inf, -np.inf], np.nan)
    cur_num = cur[emb_cols].apply(pd.to_numeric, errors="coerce").replace([np.inf, -np.inf], np.nan)
    ref_cent = ref_num.mean(axis=0).fillna(0.0).values.astype(float)
    cur_cent = cur_num.mean(axis=0).fillna(0.0).values.astype(float)
    return float(np.linalg.norm(cur_cent - ref_cent))


def main():
    parser = argparse.ArgumentParser(description="Compute drift report between reference and current fusion datasets.")
    parser.add_argument("--reference", default="data/processed/fusion_master_with_embeddings.csv")
    parser.add_argument("--current", required=True, help="New batch CSV to compare against reference.")
    parser.add_argument("--output", default="reports/fusion_drift_report.json")
    parser.add_argument("--psi-threshold", type=float, default=0.20)
    parser.add_argument("--centroid-threshold", type=float, default=1.50)
    args = parser.parse_args()

    ref = pd.read_csv(args.reference)
    cur = pd.read_csv(args.current)

    key_features = [c for c in ["p_anemia", "hr_bpm_est", "ibi_mean", "ibi_std", "peak_count"] if c in ref.columns and c in cur.columns]

    psi_scores = {}
    for c in key_features:
        psi_scores[c] = psi(ref[c], cur[c], bins=10)

    cshift = embedding_centroid_shift(ref, cur)

    max_psi = np.nanmax(list(psi_scores.values())) if psi_scores else np.nan
    retrain_recommended = False
    if not np.isnan(max_psi) and max_psi > args.psi_threshold:
        retrain_recommended = True
    if cshift is not None and cshift > args.centroid_threshold:
        retrain_recommended = True

    report = {
        "reference_rows": int(len(ref)),
        "current_rows": int(len(cur)),
        "psi_scores": psi_scores,
        "max_psi": None if np.isnan(max_psi) else float(max_psi),
        "embedding_centroid_shift": cshift,
        "thresholds": {
            "psi_threshold": float(args.psi_threshold),
            "centroid_threshold": float(args.centroid_threshold),
        },
        "retrain_recommended": bool(retrain_recommended),
    }

    ensure_dir(os.path.dirname(args.output) or ".")
    save_json(report, args.output)
    print("Saved drift report:", args.output)
    print(report)


if __name__ == "__main__":
    main()