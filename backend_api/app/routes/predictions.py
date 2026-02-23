from __future__ import annotations
from fastapi import APIRouter, HTTPException, Request
from app.schemas.fusion_prediction import (
    FusionPredictionRequest,
    FusionPredictionResponse,
)

router = APIRouter(prefix="/api/v1/predictions", tags=["predictions"])


@router.post("/pph-proxy", response_model=FusionPredictionResponse)
def predict_pph_proxy(payload: FusionPredictionRequest, request: Request):
    """
    Expects a flat feature map matching the fusion training features.json.
    """
    svc = request.app.state.fusion_service

    if not svc.is_loaded():
        raise HTTPException(status_code=503, detail="Fusion model is not loaded")

    try:
        result = svc.predict_from_feature_map(payload.features)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fusion inference error: {str(e)}")