import numpy as np
from sklearn.model_selection import StratifiedKFold
from tensorflow.keras.models import Model

def generate_oof_embeddings(
    pixel_builder,
    hb_builder,
    config,
    X_pix,
    X_hb,
    y
):

    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

    embedding_dim = config["pixel"]["embedding_dim"]

    oof_pixel = np.zeros((len(y), embedding_dim))
    oof_hb = np.zeros((len(y), 1))

    scale_pos_weight = (len(y) - sum(y)) / sum(y)

    for fold, (train_idx, val_idx) in enumerate(skf.split(X_pix, y)):

        print(f"Fold {fold+1}/5")

        # Pixel model
        pixel_model = pixel_builder(config["pixel"])
        pixel_model.fit(
            X_pix[train_idx], y[train_idx],
            epochs=config["pixel"]["epochs"],
            batch_size=config["pixel"]["batch_size"],
            verbose=0
        )

        embedding_model = Model(
            pixel_model.input,
            pixel_model.get_layer("embedding").output
        )

        oof_pixel[val_idx] = embedding_model.predict(X_pix[val_idx], verbose=0)

        # Hb model
        hb_model = hb_builder(config["hb"], scale_pos_weight)
        hb_model.fit(X_hb[train_idx], y[train_idx])
        oof_hb[val_idx] = hb_model.predict_proba(X_hb[val_idx])[:,1:2]

    return oof_pixel, oof_hb