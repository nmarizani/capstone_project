import 'package:equatable/equatable.dart';
import '../../data/models/fusion_prediction_response.dart';

class PredictionState extends Equatable {
  final bool isLoading;
  final FusionPredictionResponse? response;
  final String? error;

  const PredictionState({
    this.isLoading = false,
    this.response,
    this.error,
  });

  PredictionState copyWith({
    bool? isLoading,
    FusionPredictionResponse? response,
    String? error,
  }) {
    return PredictionState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, response, error];
}