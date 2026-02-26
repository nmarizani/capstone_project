import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../models/fusion_prediction_request.dart';
import '../models/fusion_prediction_response.dart';

class PredictionRepository {
  final ApiClient apiClient;

  PredictionRepository(this.apiClient);

  Future<FusionPredictionResponse> predictPphProxy(
      FusionPredictionRequest request,
      ) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/predictions/pph-proxy',
        data: request.toJson(),
      );

      return FusionPredictionResponse.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message ?? 'Network error';
      throw Exception('Prediction request failed: $msg');
    }
  }
}