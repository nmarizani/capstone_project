from __future__ import annotations
import glob
import json
import os
from dataclasses import dataclass
from typing import Any, Dict, List, Optional
import joblib
import numpy as np
import pandas as pd
from app.services.explanation_engine import generate_explanations_and_actions


@dataclass
class FusionArtifacts:
    model: Any
    calibrator: Any
    threshold: float
    feature_names: List[str]
    version_dir: str
    label_type: str = "proxy_rule_v1"


class FusionInferenceService:
    def __init__(self, artifacts_root: str = "models_artifacts/fusion_pph_proxy"):
        self.artifacts_root = artifacts_root
        self.artifacts: Optional[FusionArtifacts] = None

    def load(self) -> None:
        version_dir = self._latest_version_dir(self.artifacts_root)
        if version_dir is None:
            raise FileNotFoundError(f"No artifact versions found in: {self.artifacts_root}")

        model_path = os.path.join(version_dir, "model.pkl")
        calibrator_path = os.path.join(version_dir, "calibrator.pkl")
        threshold_path = os.path.join(version_dir, "threshold.json")
        features_path = os.path.join(version_dir, "features.json")

        if not os.path.exists(model_path):
            raise FileNotFoundError(model_path)
        if not os.path.exists(calibrator_path):
            raise FileNotFoundError(calibrator_path)
        if not os.path.exists(threshold_path):
            raise FileNotFoundError(threshold_path)
        if not os.path.exists(features_path):
            raise FileNotFoundError(features_path)

        model = joblib.load(model_path)
        calibrator = joblib.load(calibrator_path)

        with open(threshold_path, "r", encoding="utf-8") as f:
            threshold_obj = json.load(f)
        threshold = float(threshold_obj.get("threshold", 0.5))
        label_type = str(threshold_obj.get("target", "pph_proxy_v1"))

        with open(features_path, "r", encoding="utf-8") as f:
            features_obj = json.load(f)

        # supports {"features": [...]} or plain list
        if isinstance(features_obj, dict):
            feature_names = features_obj.get("features", [])
        elif isinstance(features_obj, list):
            feature_names = features_obj
        else:
            raise ValueError("Invalid features.json format")

        if not feature_names:
            raise ValueError("No features found in features.json")

        self.artifacts = FusionArtifacts(
            model=model,
            calibrator=calibrator,
            threshold=threshold,
            feature_names=feature_names,
            version_dir=version_dir,
            label_type=label_type,
        )

    def is_loaded(self) -> bool:
        return self.artifacts is not None

    def predict_from_feature_map(self, feature_map: Dict[str, Any]) -> Dict[str, Any]:
        if self.artifacts is None:
            raise RuntimeError("Fusion artifacts not loaded")

        art = self.artifacts

        x_row, missing_features, non_numeric_features = self._build_feature_row(
            feature_map=feature_map,
            ordered_features=art.feature_names,
        )

       # Base model probability
        base_prob = float(art.model.predict_proba(x_row)[0, 1])

       # Platt calibration (expects shape [n_samples, 1])
        cal_prob = float(art.calibrator.predict_proba(np.array([[base_prob]], dtype=np.float32))[0, 1])

       # Label based on calibrated probability
        label = int(cal_prob >= art.threshold)

       # NEW: explanation layer
        exp = generate_explanations_and_actions(
             feature_map=feature_map,
        prob=cal_prob,
        threshold=art.threshold,
        label=label,
    )

        return {
            "status": "ok",
            "prediction": {
                "pph_proxy_probability": cal_prob,
                "pph_proxy_label": label,
                "threshold_used": art.threshold,
                "risk_band": exp["risk_band"],  # <- now consistent with threshold
                "base_model_probability": base_prob,
            },
            "explanations": exp["explanations"],
            "recommended_actions": exp["recommended_actions"],
            "warnings": exp["warnings"] + self._build_warnings(missing_features, non_numeric_features),
            "model_info": {
                "fusion_model_version": os.path.basename(art.version_dir.rstrip("\\/")),
                "artifacts_path": art.version_dir,
                "label_type": art.label_type,
                "calibrated": True,
                "n_features_expected": len(art.feature_names),
       },
        }
    @staticmethod
    def _latest_version_dir(root: str) -> Optional[str]:
        candidates = sorted(glob.glob(os.path.join(root, "*")))
        candidates = [c for c in candidates if os.path.isdir(c)]
        return candidates[-1] if candidates else None

    @staticmethod
    def _build_feature_row(feature_map: Dict[str, Any], ordered_features: List[str]) -> tuple[np.ndarray, List[str], List[str]]:
        values: List[float] = []
        missing_features: List[str] = []
        non_numeric_features: List[str] = []

        for f in ordered_features:
            if f not in feature_map:
                values.append(0.0)
                missing_features.append(f)
                continue

            v = feature_map[f]
            try:
                if v is None:
                    values.append(0.0)
                else:
                    values.append(float(v))
            except (TypeError, ValueError):
                values.append(0.0)
                non_numeric_features.append(f)

        arr = np.array(values, dtype=np.float32).reshape(1, -1)
        arr = np.nan_to_num(arr, nan=0.0, posinf=0.0, neginf=0.0)
        return arr, missing_features, non_numeric_features

    @staticmethod
    def _build_warnings(missing_features: List[str], non_numeric_features: List[str]) -> List[str]:
        warnings = []
        if missing_features:
            preview = ", ".join(missing_features[:10])
            suffix = "..." if len(missing_features) > 10 else ""
            warnings.append(f"Missing {len(missing_features)} expected features (imputed to 0.0): {preview}{suffix}")
        if non_numeric_features:
            preview = ", ".join(non_numeric_features[:10])
            suffix = "..." if len(non_numeric_features) > 10 else ""
            warnings.append(f"Non-numeric values in {len(non_numeric_features)} features (coerced to 0.0): {preview}{suffix}")
        return warnings

    @staticmethod
    def _to_risk_band(prob: float, threshold: float) -> str:
        # Simple UX banding
        if prob >= max(threshold, 0.70):
            return "high"
        if prob >= max(threshold * 0.75, 0.40):
            return "moderate"
        return "low"