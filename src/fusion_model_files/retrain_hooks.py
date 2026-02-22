from __future__ import annotations
import argparse
import glob
import os
from typing import Optional
from src.fusion_model_files.utils import load_json


def _latest_version_dir(root: str) -> Optional[str]:
    candidates = sorted(glob.glob(os.path.join(root, "*")))
    candidates = [c for c in candidates if os.path.isdir(c)]
    return candidates[-1] if candidates else None


def _load_metric(path: str, key: str, default=None):
    if not os.path.exists(path):
        return default
    d = load_json(path)
    return d.get(key, default)


def champion_challenger_decision(
    champion_dir: str,
    challenger_dir: str,
    min_pr_auc_delta: float = 0.0,
    max_recall_drop: float = 0.02,
) -> dict:
    champ_metrics_path = os.path.join(champion_dir, "metrics.json")
    chal_metrics_path = os.path.join(challenger_dir, "metrics.json")

    champ = load_json(champ_metrics_path)
    chal = load_json(chal_metrics_path)

    champ_pr = champ.get("pr_auc_oof_cal")
    chal_pr = chal.get("pr_auc_oof_cal")
    champ_recall = champ.get("recall_oof")
    chal_recall = chal.get("recall_oof")

    decision = False
    reasons = []

    if champ_pr is None or chal_pr is None:
        reasons.append("Missing PR-AUC metric.")
    else:
        if chal_pr + 1e-12 >= champ_pr + min_pr_auc_delta:
            reasons.append("PR-AUC criterion passed.")
            decision = True
        else:
            reasons.append("PR-AUC criterion failed.")

    if champ_recall is not None and chal_recall is not None:
        if chal_recall + max_recall_drop < champ_recall:
            decision = False
            reasons.append("Recall dropped beyond allowed tolerance.")
        else:
            reasons.append("Recall within tolerance.")

    return {
        "promote_challenger": bool(decision),
        "champion_dir": champion_dir,
        "challenger_dir": challenger_dir,
        "champion_pr_auc": champ_pr,
        "challenger_pr_auc": chal_pr,
        "champion_recall": champ_recall,
        "challenger_recall": chal_recall,
        "reasons": reasons,
    }


def main():
    parser = argparse.ArgumentParser(description="Champion-challenger promotion decision for fusion proxy models.")
    parser.add_argument("--champion-root", default="models_artifacts/fusion_pph_proxy")
    parser.add_argument("--challenger-dir", required=True, help="Path to newly trained challenger artifact directory.")
    parser.add_argument("--min-pr-auc-delta", type=float, default=0.0)
    parser.add_argument("--max-recall-drop", type=float, default=0.02)
    args = parser.parse_args()

    champion_dir = _latest_version_dir(args.champion_root)
    if champion_dir is None:
        print("[INFO] No existing champion found. Promote challenger by default.")
        print({"promote_challenger": True, "challenger_dir": args.challenger_dir, "reason": "No champion exists"})
        return

    result = champion_challenger_decision(
        champion_dir=champion_dir,
        challenger_dir=args.challenger_dir,
        min_pr_auc_delta=args.min_pr_auc_delta,
        max_recall_drop=args.max_recall_drop,
    )
    print(result)


if __name__ == "__main__":
    main()