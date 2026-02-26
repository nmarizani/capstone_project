class FusionPredictionRequest {
  final String? patientLocalId;
  final String? visitId;
  final Map<String, double> features;
  final Map<String, dynamic>? meta;

  FusionPredictionRequest({
    this.patientLocalId,
    this.visitId,
    required this.features,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'patient_local_id': patientLocalId,
    'visit_id': visitId,
    'features': features,
    'meta': meta,
  };
}