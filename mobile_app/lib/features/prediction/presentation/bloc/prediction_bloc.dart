import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/fusion_prediction_request.dart';
import '../../data/repositories/prediction_repository.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final PredictionRepository repository;

  PredictionBloc(this.repository) : super(const PredictionState()) {
    on<SubmitPredictionRequested>(_onSubmitPredictionRequested);
  }

  Future<void> _onSubmitPredictionRequested(
      SubmitPredictionRequested event,
      Emitter<PredictionState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final req = FusionPredictionRequest(
        patientLocalId: event.patientLocalId,
        visitId: event.visitId,
        features: event.features,
        meta: {
          'source': 'flutter_app',
          'mode': 'online',
        },
      );

      final result = await repository.predictPphProxy(req);

      emit(PredictionState(isLoading: false, response: result));
    } catch (e) {
      emit(PredictionState(isLoading: false, error: e.toString()));
    }
  }
}