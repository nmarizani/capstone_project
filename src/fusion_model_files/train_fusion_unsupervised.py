from __future__ import annotations
import argparse
import os
from typing import List
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from tensorflow.keras import Model
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, TerminateOnNaN
from tensorflow.keras.layers import BatchNormalization, Dense, Dropout, Input
from src.fusion_model_files.utils import ensure_dir, save_json, timestamp_version


def choose_fusion_feature_columns(df: pd.DataFrame) -> List[str]:
    drop_exact = {
        "row_id",
        "Risk Level",
        "pph", "pph_proxy_v1", "pph_proxy_score_v1", "pph_proxy_label_type",
        "Label", "anaemic", "Anaemic"
    }
    cols = []
    for c in df.columns:
        if c in drop_exact:
            continue
        if pd.api.types.is_numeric_dtype(df[c]):
            cols.append(c)
    return cols


def add_noise(x: np.ndarray, std: float = 0.10) -> np.ndarray:
    noisy = x + np.random.normal(0, std, size=x.shape)
    noisy = np.nan_to_num(noisy, nan=0.0, posinf=0.0, neginf=0.0)
    return np.clip(noisy, -8, 8)


def build_dae(input_dim: int, emb_dim: int = 32) -> tuple[Model, Model]:
    inp = Input(shape=(input_dim,), name="fusion_input")

    x = Dense(128, activation="relu")(inp)
    x = BatchNormalization()(x)
    x = Dropout(0.20)(x)

    x = Dense(64, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.20)(x)

    emb = Dense(emb_dim, activation="relu", name="fusion_embedding")(x)

    y = Dense(64, activation="relu")(emb)
    y = BatchNormalization()(y)
    y = Dropout(0.15)(y)

    y = Dense(128, activation="relu")(y)
    out = Dense(input_dim, activation="linear", name="reconstruction")(y)

    auto = Model(inp, out, name="fusion_dae")
    encoder = Model(inp, emb, name="fusion_encoder")
    auto.compile(optimizer=tf.keras.optimizers.Adam(1e-3), loss="mse")
    return auto, encoder


def main():
    parser = argparse.ArgumentParser(description="Train unsupervised fusion denoising autoencoder and export fusion embeddings.")
    parser.add_argument("--input", default="data/processed/fusion_master_with_proxy.csv")
    parser.add_argument("--output-csv", default="data/processed/fusion_master_with_embeddings.csv")
    parser.add_argument("--artifacts-root", default="models_artifacts/fusion_encoder")
    parser.add_argument("--emb-dim", type=int, default=32)
    parser.add_argument("--epochs", type=int, default=200)
    parser.add_argument("--batch-size", type=int, default=32)
    args = parser.parse_args()

    df = pd.read_csv(args.input)
    feat_cols = choose_fusion_feature_columns(df)
    if not feat_cols:
        raise ValueError("No numeric fusion feature columns found.")

    X_df = df[feat_cols].copy()
    X_df = X_df.replace([np.inf, -np.inf], np.nan)
    X_df = X_df.fillna(X_df.median(numeric_only=True))
    X = X_df.values.astype(np.float32)

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    X_tr, X_val = train_test_split(X_scaled, test_size=0.2, random_state=42)

    auto, encoder = build_dae(input_dim=X_scaled.shape[1], emb_dim=args.emb_dim)

    history = auto.fit(
        add_noise(X_tr, 0.10), X_tr,
        validation_data=(add_noise(X_val, 0.10), X_val),
        epochs=args.epochs,
        batch_size=args.batch_size,
        callbacks=[
            TerminateOnNaN(),
            EarlyStopping(patience=15, restore_best_weights=True),
            ReduceLROnPlateau(patience=6, factor=0.5)
        ],
        verbose=1
    )

    fusion_emb = encoder.predict(X_scaled, verbose=0)
    emb_cols = [f"fusion_emb_{i}" for i in range(args.emb_dim)]
    df_emb = pd.DataFrame(fusion_emb, columns=emb_cols, index=df.index)

    out_df = pd.concat([df.reset_index(drop=True), df_emb.reset_index(drop=True)], axis=1)
    ensure_dir(os.path.dirname(args.output_csv) or ".")
    out_df.to_csv(args.output_csv, index=False)
    print("Saved:", args.output_csv, out_df.shape)

    version = timestamp_version()
    out_dir = ensure_dir(os.path.join(args.artifacts_root, version))

    encoder.save(os.path.join(out_dir, "encoder.h5"))
    auto.save(os.path.join(out_dir, "autoencoder.h5"))
    joblib.dump(scaler, os.path.join(out_dir, "scaler.pkl"))

    save_json(
        {
            "input_csv": args.input,
            "output_csv": args.output_csv,
            "feature_columns": feat_cols,
            "embedding_dim": args.emb_dim,
            "train_rows": int(len(X_tr)),
            "val_rows": int(len(X_val)),
            "final_train_loss": float(history.history["loss"][-1]),
            "final_val_loss": float(history.history["val_loss"][-1]),
        },
        os.path.join(out_dir, "metadata.json"),
    )

    # Save training curve
    try:
        import matplotlib.pyplot as plt

        fig_dir = ensure_dir("reports/figures/fusion")
        plt.figure(figsize=(8, 4))
        plt.plot(history.history["loss"], label="train")
        plt.plot(history.history["val_loss"], label="val")
        plt.xlabel("Epoch")
        plt.ylabel("MSE")
        plt.title("Fusion DAE Training Curve")
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(fig_dir, "fusion_dae_loss_curve.png"), dpi=150)
        plt.close()
    except Exception as e:
        print("[WARN] Could not save training curve:", e)

    print("Artifacts:", out_dir)


if __name__ == "__main__":
    main()