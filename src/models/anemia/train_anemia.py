import os
import yaml
import joblib
import json
import numpy as np
import pandas as pd

from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, f1_score, average_precision_score

from src.models.anemia.pixel_model import build_pixel_model
from src.models.anemia.hb_model import build_hb_model
from src.models.anemia.stacking import generate_oof_embeddings
from src.models.anemia.fusion_model import build_fusion_model
from src.evaluation.threshold_search import optimize_threshold


def train():

    # Loading config
    with open("src/config/anemia.yaml") as f:
        config = yaml.safe_load(f)

    df = pd.read_csv("data/processed/anemia_cleaned.csv")

    X_pixels = df[['red_pixel_pct','green_pixel_pct','blue_pixel_pct',
                   'rgb_sum','red_green_ratio','pallor_index']].values

    X_hb = df[['hemoglobin_gdl']].values
    y = (df['anaemic'] == 'Yes').astype(int).values

    X_train_pix, X_test_pix, X_train_hb, X_test_hb, y_train, y_test = \
        train_test_split(X_pixels, X_hb, y, test_size=0.2,
                         random_state=42, stratify=y)

    scaler = StandardScaler()
    X_train_pix = scaler.fit_transform(X_train_pix)
    X_test_pix = scaler.transform(X_test_pix)

    # OOF Stacking to generate embeddings for fusion model training
    oof_pixel, oof_hb = generate_oof_embeddings(
        build_pixel_model,
        build_hb_model,
        config,
        X_train_pix,
        X_train_hb,
        y_train
    )

    X_train_fused = np.concatenate([oof_pixel, oof_hb], axis=1)

    scale_pos_weight = (len(y_train) - sum(y_train)) / sum(y_train)

    fusion_model = build_fusion_model(config["fusion"], scale_pos_weight)
    fusion_model.fit(X_train_fused, y_train)

    # Test Evalution
    # Training full pixel + hb on full train set for test predictions

    pixel_model = build_pixel_model(config["pixel"])
    pixel_model.fit(X_train_pix, y_train, epochs=config["pixel"]["epochs"], verbose=0)

    from tensorflow.keras.models import Model
    embedding_model = Model(pixel_model.input,
                            pixel_model.get_layer("embedding").output)

    pixel_test_emb = embedding_model.predict(X_test_pix, verbose=0)

    hb_model = build_hb_model(config["hb"], scale_pos_weight)
    hb_model.fit(X_train_hb, y_train)
    hb_test_prob = hb_model.predict_proba(X_test_hb)[:,1:2]

    X_test_fused = np.concatenate([pixel_test_emb, hb_test_prob], axis=1)

    y_prob = fusion_model.predict_proba(X_test_fused)[:,1]

    auc = roc_auc_score(y_test, y_prob)
    pr_auc = average_precision_score(y_test, y_prob)

    best_threshold = optimize_threshold(y_test, y_prob)
    f1 = f1_score(y_test, y_prob >= best_threshold)

    print("AUC:", auc)
    print("PR-AUC:", pr_auc)
    print("Best Threshold:", best_threshold)
    print("F1:", f1)

    # Save Artifacts

    version = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_path = f"models_artifacts/anemia/{version}"
    os.makedirs(save_path, exist_ok=True)

    pixel_model.save(f"{save_path}/pixel_model.h5")
    joblib.dump(hb_model, f"{save_path}/hb_model.pkl")
    joblib.dump(fusion_model, f"{save_path}/fusion_model.pkl")
    joblib.dump(scaler, f"{save_path}/scaler.pkl")

    metadata = {
        "auc": float(auc),
        "pr_auc": float(pr_auc),
        "f1": float(f1),
        "threshold": float(best_threshold)
    }

    with open(f"{save_path}/metrics.json", "w") as f:
        json.dump(metadata, f, indent=4)

    print("Saved version:", version)


if __name__ == "__main__":
    train()