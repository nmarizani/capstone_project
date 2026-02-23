from __future__ import annotations
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field


class FusionPredictionRequest(BaseModel):
    patient_local_id: Optional[str] = Field(default=None, examples=["ZW-HRE-001"])
    visit_id: Optional[str] = Field(default=None, examples=["visit-2026-02-23-001"])

    # Flat feature map matching fusion training features.json
    features: Dict[str, float] = Field(
        ...,
        description="Flat numeric feature dictionary keyed by fusion feature names."
    )

    meta: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Optional metadata for tracing; ignored by the model."
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "patient_local_id": "ZW-HRE-001",
                "visit_id": "visit-2026-02-23-001",
                "features": {
                    "p_anemia": 0.81,
                    "prev_complications": 1,
                    "systolic_bp": 90,
                    "diastolic_bp": 60,
                    "hypertension_flag": 0,
                    "diabetes_any": 0
                },
                "meta": {
                    "app_version": "1.0.0",
                    "device_id": "android-test-device"
                }
            }
        }
    }

class FusionPredictionResponse(BaseModel):
    status: str
    prediction: Dict[str, Any]
    explanations: list[str] = []
    recommended_actions: list[str] = []
    warnings: list[str] = []
    model_info: Dict[str, Any]
