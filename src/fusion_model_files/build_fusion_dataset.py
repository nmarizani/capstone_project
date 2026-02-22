from __future__ import annotations
import argparse
from typing import List
import numpy as np
import pandas as pd
from src.fusion_model_files.utils import sanitize_numeric_df


def _drop_duplicate_columns_keep_first(df: pd.DataFrame) -> pd.DataFrame:
    return df.loc[:, ~df.columns.duplicated()].copy()


def _strip_unnamed(df: pd.DataFrame) -> pd.DataFrame:
    cols = [c for c in df.columns if not str(c).lower().startswith("unnamed")]
    return df[cols].copy()


def main():
    parser = argparse.ArgumentParser(description="Build fusion master dataset from clinical, anemia, and PPG outputs.")
    parser.add_argument("--clinical", default="data/processed/clinical_with_embeddings.csv")
    parser.add_argument("--anemia", default="data/processed/anemia_with_embeddings.csv")
    parser.add_argument("--ppg", default="data/processed/ppg_with_embeddings.csv")
    parser.add_argument("--output", default="data/processed/fusion_master_table.csv")
    parser.add_argument("--join-key", default=None, help="Optional common key column (e.g., record_id). If omitted, aligns by row index.")
    args = parser.parse_args()

    clinical = _strip_unnamed(pd.read_csv(args.clinical))
    anemia = _strip_unnamed(pd.read_csv(args.anemia))
    ppg = _strip_unnamed(pd.read_csv(args.ppg))

    print("Loaded clinical:", clinical.shape)
    print("Loaded anemia  :", anemia.shape)
    print("Loaded ppg     :", ppg.shape)

    if args.join_key and all(args.join_key in d.columns for d in [clinical, anemia, ppg]):
        key = args.join_key
        # Drop likely duplicate columns from secondary tables except key
        anemia_drop = [c for c in ["anaemic", "Anaemic", "Label", "Risk Level"] if c in anemia.columns and c != key]
        ppg_drop = [c for c in ["Label", "Risk Level"] if c in ppg.columns and c != key]

        fusion = clinical.merge(
            anemia.drop(columns=anemia_drop, errors="ignore"),
            on=key,
            how="inner",
            suffixes=("", "_anemia")
        ).merge(
            ppg.drop(columns=ppg_drop, errors="ignore"),
            on=key,
            how="inner",
            suffixes=("", "_ppg")
        )
    else:
        # Row alignment mode (only safe if row order was preserved across pipelines)
        n = min(len(clinical), len(anemia), len(ppg))
        if len({len(clinical), len(anemia), len(ppg)}) != 1:
            print(f"[WARN] Row counts differ. Truncating all to n={n} for index alignment.")
        clinical = clinical.iloc[:n].reset_index(drop=True)
        anemia = anemia.iloc[:n].reset_index(drop=True)
        ppg = ppg.iloc[:n].reset_index(drop=True)

        anemia_drop = [c for c in ["anaemic", "Anaemic", "Label", "Risk Level"] if c in anemia.columns]
        ppg_drop = [c for c in ["Label", "Risk Level"] if c in ppg.columns]

        fusion = pd.concat(
            [
                clinical,
                anemia.drop(columns=anemia_drop, errors="ignore"),
                ppg.drop(columns=ppg_drop, errors="ignore")
            ],
            axis=1
        )

    fusion = _drop_duplicate_columns_keep_first(fusion)
    fusion = sanitize_numeric_df(fusion)

    # Create row_id if no explicit key
    if "row_id" not in fusion.columns:
        fusion.insert(0, "row_id", np.arange(len(fusion), dtype=int))

    # Quick summary
    n_cols = fusion.shape[1]
    emb_cols = [c for c in fusion.columns if c.endswith(tuple([str(i) for i in range(10)])) and ("_emb_" in c)]
    print("Fusion shape:", fusion.shape)
    print("Embedding columns:", len(emb_cols))
    print("Has Risk Level:", "Risk Level" in fusion.columns)

    fusion.to_csv(args.output, index=False)
    print("Saved:", args.output)


if __name__ == "__main__":
    main()