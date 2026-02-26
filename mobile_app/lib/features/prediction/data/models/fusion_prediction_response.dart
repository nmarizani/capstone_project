class FusionPredictionResponse {
  final String status;
  final PredictionPayload prediction;
  final List<String> explanations;
  final List<String> recommendedActions;
  final List<String> warnings;
  final Map<String, dynamic> modelInfo;

  FusionPredictionResponse({
    required this.status,
    required this.prediction,
    required this.explanations,
    required this.recommendedActions,
    required this.warnings,
    required this.modelInfo,
  });

  factory FusionPredictionResponse.fromJson(Map<String, dynamic> json) {
    return FusionPredictionResponse(
      status: json['status'] ?? 'unknown',
      prediction: PredictionPayload.fromJson(json['prediction'] ?? {}),
      explanations: (json['explanations'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      recommendedActions: (json['recommended_actions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      warnings:
      (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
      modelInfo: Map<String, dynamic>.from(json['model_info'] ?? {}),
    );
  }
}

class PredictionPayload {
  final double pphProxyProbability;
  final int pphProxyLabel;
  final double thresholdUsed;
  final String riskBand;
  final double? baseModelProbability;

  PredictionPayload({
    required this.pphProxyProbability,
    required this.pphProxyLabel,
    required this.thresholdUsed,
    required this.riskBand,
    this.baseModelProbability,
  });

  factory PredictionPayload.fromJson(Map<String, dynamic> json) {
    return PredictionPayload(
      pphProxyProbability:
      (json['pph_proxy_probability'] as num?)?.toDouble() ?? 0.0,
      pphProxyLabel: (json['pph_proxy_label'] as num?)?.toInt() ?? 0,
      thresholdUsed: (json['threshold_used'] as num?)?.toDouble() ?? 0.0,
      riskBand: (json['risk_band'] ?? 'unknown').toString(),
      baseModelProbability:
      (json['base_model_probability'] as num?)?.toDouble(),
    );
  }
}