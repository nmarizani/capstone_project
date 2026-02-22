import pandas as pd

df = pd.read_csv("data/processed/fusion_master_with_proxy.csv")

# 1) Check proxy score distribution
print(df["pph_proxy_score_v1"].describe())

# 2) Check top scores
print(df["pph_proxy_score_v1"].sort_values(ascending=False).head(10))

# 3) Check how many would be positive at lower thresholds
for t in [0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55]:
    prev = (df["pph_proxy_score_v1"] >= t).mean()
    print(f"threshold={t:.2f} -> prevalence={prev:.3f}")

# 4) Check whether key columns exist
needed = [
    "p_anemia", "hr_bpm_est", "ibi_std", "peak_count",
    "prev_complications", "hypertension_flag", "diabetes_any",
    "systolic_bp", "diastolic_bp", "map_mmhg", "pulse_pressure", "Risk Level"
]
print({c: (c in df.columns) for c in needed})

# 5) Inspect key columns if present
for c in needed:
    if c in df.columns:
        print("\n", c)
        print(df[c].head())
        print(df[c].describe(include="all"))