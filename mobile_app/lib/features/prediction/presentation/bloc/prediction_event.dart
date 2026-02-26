import 'package:equatable/equatable.dart';

class PredictionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitPredictionRequested extends PredictionEvent {
  final String patientLocalId;
  final String visitId;
  final Map<String, double> features;

  SubmitPredictionRequested({
    required this.patientLocalId,
    required this.visitId,
    required this.features,
  });

  @override
  List<Object?> get props => [patientLocalId, visitId, features];
}