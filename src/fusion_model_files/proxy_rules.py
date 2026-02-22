from __future__ import annotations
import argparse
import numpy as np
import pandas as pd


def _clip01(x):
    return np.clip(x, 0.0, 1.0)


def _as_num(s: pd.Series) -> pd.Series:
    return pd.to_numeric(s, errors="coerce").astype(float)


def _minmax_series(s: pd.Series, lo=None, hi=None) -> pd.Series:
    s = _as_num(s)
    valid = s.dropna()
    if valid.empty:
        return pd.Series(0.0, index=s.index)
    if lo is None:
        lo = float(valid.quantile(0.05))
    if hi is None:
        hi = float(valid.quantile(0.95))
    if hi <= lo:
        return pd.Series(0.0, index=s.index)
    return pd.Series(_clip01((s - lo) / (hi - lo + 1e-6)), index=s.index).fillna(0.0)


def _tachy_score(hr: pd.Series, low: float = 90, high: float = 130) -> pd.Series:
    hr = _as_num(hr)
    return pd.Series(_clip01((hr - low) / (high - low + 1e-6)), index=hr.index).fillna(0.0)


def _bp_extreme_score(bp: pd.Series, low_bad: float, low_ok: float, high_ok: float, high_bad: float) -> pd.Series:
    bp = _as_num(bp)
    score_low = _clip01((low_ok - bp) / (low_ok - low_bad + 1e-6))
    score_high = _clip01((bp - high_ok) / (high_bad - high_ok + 1e-6))
    out = np.maximum(score_low, score_high)
    return pd.Series(out, index=bp.index).fillna(0.0)


def build_pph_proxy_rule_v1(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()

    # Anemia burden
    if "p_anemia" in out.columns:
        anemia = _as_num(out["p_anemia"]).fillna(0.0).clip(0, 1)
    else:
        anemia = pd.Series(0.0, index=out.index)

    # Hemodynamic stress (PPG proxies)
    hr_score = _tachy_score(out["hr_bpm_est"]) if "hr_bpm_est" in out.columns else pd.Series(0.0, index=out.index)
    ibi_var_score = _minmax_series(out["ibi_std"]) if "ibi_std" in out.columns else pd.Series(0.0, index=out.index)

    if "peak_count" in out.columns:
        peak_count = _as_num(out["peak_count"]).fillna(0.0)
        peak_penalty = pd.Series(_clip01((3.0 - peak_count) / 3.0), index=out.index).fillna(0.0)
    else:
        peak_penalty = pd.Series(0.0, index=out.index)

    amp_score = _minmax_series(-_as_num(out["ppg_amp_mean"])) if "ppg_amp_mean" in out.columns else pd.Series(0.0, index=out.index)

    hemo = (0.45 * hr_score + 0.30 * ibi_var_score + 0.15 * peak_penalty + 0.10 * amp_score).clip(0, 1)

    # Clinical burden
    clinical_terms = []

    for col in ["prev_complications", "hypertension_flag", "diabetes_any", "preexist_diabetes", "gest_diabetes"]:
        if col in out.columns:
            clinical_terms.append(_as_num(out[col]).fillna(0.0).clip(0, 1))

    if "systolic_bp" in out.columns:
        clinical_terms.append(_bp_extreme_score(out["systolic_bp"], low_bad=70, low_ok=90, high_ok=140, high_bad=180))
    if "diastolic_bp" in out.columns:
        clinical_terms.append(_bp_extreme_score(out["diastolic_bp"], low_bad=40, low_ok=60, high_ok=90, high_bad=110))
    if "map_mmhg" in out.columns:
        clinical_terms.append(_bp_extreme_score(out["map_mmhg"], low_bad=50, low_ok=65, high_ok=105, high_bad=130))
    if "pulse_pressure" in out.columns:
        clinical_terms.append(_minmax_series(out["pulse_pressure"]))

    clinical = pd.concat(clinical_terms, axis=1).mean(axis=1).fillna(0.0) if clinical_terms else pd.Series(0.0, index=out.index)

    # Maternal risk prior
    if "Risk Level" in out.columns:
        rl = out["Risk Level"].astype(str).str.strip().str.lower()
        rl_score = rl.map({"low": 0.1, "medium": 0.5, "high": 0.9}).fillna(0.0)
    else:
        rl_score = pd.Series(0.0, index=out.index)

    # Weighted proxy score
    out["pph_proxy_score_v1"] = (
        0.35 * anemia +
        0.35 * hemo +
        0.25 * clinical +
        0.05 * rl_score
    ).clip(0, 1)

    out["pph_proxy_label_type"] = "proxy_rule_v1"
    return out


def assign_proxy_labels(
    df: pd.DataFrame,
    threshold_mode: str = "fixed",
    threshold: float = 0.55,
    quantile: float = 0.85,
) -> tuple[pd.DataFrame, float, str]:
    out = df.copy()

    if "pph_proxy_score_v1" not in out.columns:
        raise ValueError("pph_proxy_score_v1 not found. Run build_pph_proxy_rule_v1 first.")

    scores = pd.to_numeric(out["pph_proxy_score_v1"], errors="coerce").fillna(0.0)

    if threshold_mode == "fixed":
        t = float(threshold)
        mode_desc = f"fixed:{t:.4f}"

    elif threshold_mode == "quantile":
        if not (0.0 < quantile < 1.0):
            raise ValueError(f"--quantile must be between 0 and 1 (exclusive), got {quantile}")
        t = float(scores.quantile(quantile))
        mode_desc = f"quantile:{quantile:.4f}->threshold:{t:.6f}"

    else:
        raise ValueError(f"Unknown threshold_mode='{threshold_mode}'. Use 'fixed' or 'quantile'.")

    out["pph_proxy_v1"] = (scores >= t).astype(int)
    out["pph_proxy_threshold_used"] = t
    out["pph_proxy_threshold_mode"] = threshold_mode

    return out, t, mode_desc


def main():
    parser = argparse.ArgumentParser(description="Add pph proxy rule v1 columns to fusion master table.")
    parser.add_argument("--input", default="data/processed/fusion_master_table.csv")
    parser.add_argument("--output", default="data/processed/fusion_master_with_proxy.csv")

    # Threshold behavior
    parser.add_argument("--threshold-mode", choices=["fixed", "quantile"], default="fixed")
    parser.add_argument("--threshold", type=float, default=0.55, help="Used when --threshold-mode fixed")
    parser.add_argument("--quantile", type=float, default=0.85, help="Used when --threshold-mode quantile (e.g., 0.85 => top 15% positive)")

    args = parser.parse_args()

    df = pd.read_csv(args.input)

    # Build continuous proxy score
    out = build_pph_proxy_rule_v1(df)

    # Assign binary labels using chosen mode
    out, t, mode_desc = assign_proxy_labels(
        out,
        threshold_mode=args.threshold_mode,
        threshold=args.threshold,
        quantile=args.quantile,
    )

    out.to_csv(args.output, index=False)

    # Debug summary
    scores = out["pph_proxy_score_v1"]
    print(scores.describe())
    print(scores.sort_values(ascending=False).head(10))

    for thr in [0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55]:
        prev = (scores >= thr).mean()
        print(f"threshold={thr:.2f} -> prevalence={prev:.3f}")

    print(f"\nThreshold mode used: {mode_desc}")
    print(f"Saved: {args.output} | shape={out.shape}")
    print(f"Proxy prevalence: {float(out['pph_proxy_v1'].mean()):.4f}")


if __name__ == "__main__":
    main()