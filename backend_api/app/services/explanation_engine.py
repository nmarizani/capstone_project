from __future__ import annotations
from typing import Any, Dict, List

def _to_float(x, default=0.0) -> float:
    try:
        return float(x)
    except (TypeError, ValueError):
        return default


def _to_int(x, default=0) -> int:
    try:
        return int(float(x))
    except (TypeError, ValueError):
        return default


def compute_risk_band(prob: float, threshold: float) -> str:
    """
    Make risk bands consistent with the model threshold.
    This avoids cases like label=1 but risk_band='low'.
    """
    if prob < threshold:
        return "low"

    # Margin above threshold (adaptive)
    margin1 = max(0.08, threshold * 0.5)
    margin2 = max(0.20, threshold * 1.2)

    if prob < threshold + margin1:
        return "moderate"
    if prob < threshold + margin2:
        return "high"
    return "critical"


def generate_explanations_and_actions(
    feature_map: Dict[str, Any],
    prob: float,
    threshold: float,
    label: int,
) -> Dict[str, List[str] | str]:
    explanations: List[str] = []
    actions: List[str] = []
    warnings: List[str] = []

    # Pull common inputs used in your current pipeline
    p_anemia = _to_float(feature_map.get("p_anemia"), 0.0)
    sbp = _to_float(feature_map.get("systolic_bp"), 0.0)
    dbp = _to_float(feature_map.get("diastolic_bp"), 0.0)
    prev_comp = _to_int(feature_map.get("prev_complications"), 0)
    hr = _to_float(feature_map.get("hr_bpm_est"), 0.0)
    signal_quality = _to_float(feature_map.get("signal_quality"), -1.0)

    # Risk band
    risk_band = compute_risk_band(prob, threshold)

    # Explanation rules
    # Anemia contribution
    if p_anemia >= 0.70:
        explanations.append("Anemia probability is elevated.")
    elif p_anemia >= 0.40:
        explanations.append("Anemia probability is moderately elevated.")

    # Blood pressure patterns
    if sbp > 0 and dbp > 0:
        if sbp < 90 or dbp < 60:
            explanations.append("Blood pressure pattern suggests possible hemodynamic instability.")
        elif sbp >= 140 or dbp >= 90:
            explanations.append("Blood pressure pattern is outside expected range.")
        elif (sbp - dbp) < 25 or (sbp - dbp) > 70:
            explanations.append("Blood pressure pattern is outside expected range.")

    # HR/PPG if available
    if hr > 0:
        if hr >= 110:
            explanations.append("Heart rate is elevated.")
        elif hr >= 95:
            explanations.append("Heart rate is mildly elevated.")

    # Clinical history
    if prev_comp == 1:
        explanations.append("History of previous complications increases maternal risk.")

    # If model positive but few rule explanations triggered, add generic model-driven explanation
    if label == 1 and len(explanations) == 0:
        explanations.append("Combined multimodal risk pattern is above the current alert threshold.")

    # Warnings
    warnings.append("Proxy model output (not confirmed PPH diagnosis).")

    if signal_quality >= 0 and signal_quality < 0.60:
        warnings.append("PPG signal quality is low; repeat measurement may improve reliability.")

    # Recommended actions (vary by risk band)
    # Base action always
    actions.append("Assess bleeding signs and uterine tone per protocol.")

    if risk_band == "low":
        actions.insert(0, "Continue routine monitoring and repeat vitals at the next scheduled interval.")
        if label == 1:
            # positive but near-threshold
            actions.insert(0, "Repeat vital signs measurement within 10 minutes to confirm trend.")

    elif risk_band == "moderate":
        actions.insert(0, "Repeat vital signs measurement within 5 minutes.")
        actions.append("Increase observation frequency and reassess symptoms.")

    elif risk_band == "high":
        actions.insert(0, "Repeat vital signs measurement immediately and confirm sensor placement.")
        actions.append("Escalate to supervising clinician now.")

    elif risk_band == "critical":
        actions.insert(0, "Initiate urgent reassessment now and repeat vitals immediately.")
        actions.append("Escalate to supervising clinician now.")
        actions.append("Prepare emergency response workflow per facility protocol.")

    # Avoid duplicates while preserving order
    actions = list(dict.fromkeys(actions))
    explanations = list(dict.fromkeys(explanations))
    warnings = list(dict.fromkeys(warnings))

    return {
        "risk_band": risk_band,
        "explanations": explanations,
        "recommended_actions": actions,
        "warnings": warnings,
    }