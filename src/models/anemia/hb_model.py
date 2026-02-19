import xgboost as xgb

def build_hb_model(config, scale_pos_weight):

    return xgb.XGBClassifier(
        n_estimators=config["n_estimators"],
        max_depth=config["max_depth"],
        learning_rate=config["learning_rate"],
        subsample=config["subsample"],
        colsample_bytree=config["colsample_bytree"],
        gamma=config["gamma"],
        min_child_weight=config["min_child_weight"],
        scale_pos_weight=scale_pos_weight,
        eval_metric="logloss",
        random_state=42
    )