from __future__ import annotations
import json
import os
from datetime import datetime
from typing import Iterable, List, Optional, Tuple
import joblib
import numpy as np
import pandas as pd


def ensure_dir(path: str) -> str:
    os.makedirs(path, exist_ok=True)
    return path


def timestamp_version() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def save_json(obj, path: str) -> None:
    ensure_dir(os.path.dirname(path) or ".")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, default=_json_default)


def load_json(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _json_default(x):
    if isinstance(x, (np.integer,)):
        return int(x)
    if isinstance(x, (np.floating,)):
        return float(x)
    if isinstance(x, (np.ndarray,)):
        return x.tolist()
    raise TypeError(f"Type not JSON serializable: {type(x)}")


def numeric_columns(df: pd.DataFrame) -> List[str]:
    return df.select_dtypes(include=[np.number]).columns.tolist()


def coerce_numeric_inplace(df: pd.DataFrame, cols: Iterable[str]) -> None:
    for c in cols:
        df[c] = pd.to_numeric(df[c], errors="coerce")


def sanitize_numeric_df(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    num_cols = numeric_columns(out)
    out[num_cols] = out[num_cols].replace([np.inf, -np.inf], np.nan)
    return out


def median_impute(df: pd.DataFrame) -> Tuple[pd.DataFrame, dict]:
    out = df.copy()
    medians = {}
    for c in out.columns:
        if pd.api.types.is_numeric_dtype(out[c]):
            m = float(np.nanmedian(out[c].values.astype(float))) if out[c].notna().any() else 0.0
            out[c] = out[c].fillna(m)
            medians[c] = m
    return out, medians


def robust_clip_df(df: pd.DataFrame, lower_q: float = 0.01, upper_q: float = 0.99) -> Tuple[pd.DataFrame, dict]:
    out = df.copy()
    clip_meta = {}
    for c in out.columns:
        if pd.api.types.is_numeric_dtype(out[c]):
            s = pd.to_numeric(out[c], errors="coerce")
            if s.notna().sum() < 5:
                continue
            lo = float(s.quantile(lower_q))
            hi = float(s.quantile(upper_q))
            out[c] = s.clip(lo, hi)
            clip_meta[c] = {"lo": lo, "hi": hi}
    return out, clip_meta


def split_feature_groups(columns: List[str]) -> dict:
    return {
        "clinical_embeddings": [c for c in columns if c.startswith("clin_emb_")],
        "anemia_embeddings": [c for c in columns if c.startswith("anemia_emb_")],
        "ppg_embeddings": [c for c in columns if c.startswith("ppg_emb_")],
        "fusion_embeddings": [c for c in columns if c.startswith("fusion_emb_")],
        "anemia_prob": [c for c in columns if c == "p_anemia"],
        "ppg_proxies": [c for c in columns if c in {"hr_bpm_est", "ibi_mean", "ibi_std", "peak_count", "ppg_amp_mean", "ppg_amp_std", "signal_quality"}],
    }


def pick_threshold_for_recall(y_true: np.ndarray, y_prob: np.ndarray, min_recall: float = 0.90) -> float:
    from sklearn.metrics import recall_score

    thresholds = np.linspace(0.01, 0.99, 199)
    chosen = 0.50
    best_precisionish = -1.0

    # Prefer highest threshold satisfying recall constraint
    for t in thresholds:
        pred = (y_prob >= t).astype(int)
        r = recall_score(y_true, pred, zero_division=0)
        if r >= min_recall:
            chosen = float(t)
    return chosen


def map_risk_level_to_binary(series: pd.Series) -> pd.Series:
    s = series.astype(str).str.strip().str.lower()
    return (s == "high").astype(int)


def map_risk_level_to_multiclass(series: pd.Series) -> pd.Series:
    s = series.astype(str).str.strip().str.lower()
    mapping = {"low": 0, "medium": 1, "high": 2}
    return s.map(mapping)


def save_joblib(obj, path: str) -> None:
    ensure_dir(os.path.dirname(path) or ".")
    joblib.dump(obj, path)