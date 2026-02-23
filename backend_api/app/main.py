from __future__ import annotations
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.routes.predictions import router as predictions_router
from app.services.fusion_inference_service import FusionInferenceService


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load artifacts once at startup
    fusion_service = FusionInferenceService(artifacts_root="../models_artifacts/fusion_pph_proxy")
    fusion_service.load()
    app.state.fusion_service = fusion_service
    yield


app = FastAPI(
    title="PPH Fusion Proxy API",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(predictions_router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/model-info")
def model_info():
    svc = app.state.fusion_service
    if not svc.is_loaded():
        return {"loaded": False}
    art = svc.artifacts
    return {
        "loaded": True,
        "fusion_model_version": art.version_dir.split("/")[-1].split("\\")[-1],
        "threshold": art.threshold,
        "label_type": art.label_type,
        "n_features_expected": len(art.feature_names),
    }