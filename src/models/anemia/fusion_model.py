import xgboost as xgb
from sklearn.calibration import CalibratedClassifierCV

def build_fusion_model(config, scale_pos_weight):

    base_model = xgb.XGBClassifier(
        n_estimators=config["n_estimators"],
        max_depth=config["max_depth"],
        learning_rate=config["learning_rate"],
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=scale_pos_weight,
        eval_metric="logloss",
        random_state=42
    )

    calibrated_model = CalibratedClassifierCV(
        base_model,
        method="isotonic",
        cv=3
    )

    return calibrated_model