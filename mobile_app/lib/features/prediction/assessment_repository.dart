import 'dart:convert';
import '../../db/local_db_service.dart';
import 'pph_prediction_service.dart';

/// Orchestrates the offline-first prediction flow:
/// 1. Always save request locally first
/// 2. Attempt API call if online
/// 3. Queue if offline, sync later
class AssessmentRepository {
  final PPHPredictionService _api = PPHPredictionService();

  /// Primary entry point: submit a full assessment
  /// Returns an [AssessmentOutcome] with status and result (if available)
  Future<AssessmentOutcome> submitAssessment({
    required String patientLocalId,
    required String visitId,
    required ClinicalInput clinical,
    required AnemiaFeaturesInput anemiaFeatures,
    PPGFeaturesInput? ppgFeatures,
  }) async {
    final request = PPHPredictionRequest(
      patientLocalId: patientLocalId,
      visitId: visitId,
      clinical: clinical,
      anemiaFeatures: anemiaFeatures,
      ppgFeatures: ppgFeatures,
    );

    // Step 1: Always persist locally first
    final queueId = await LocalDbService.enqueueAssessment(
      patientLocalId: patientLocalId,
      visitId: visitId,
      request: request,
    );

    // Step 2: Try API
    try {
      final result = await _api.predict(request);
      await LocalDbService.saveAssessmentResult(
        queueId: queueId,
        result: result,
      );
      return AssessmentOutcome.online(queueId: queueId, result: result);
    } on PPHApiException catch (e) {
      await LocalDbService.markAssessmentFailed(queueId);
      return AssessmentOutcome.failed(
        queueId: queueId,
        error: e.message,
      );
    } catch (_) {
      // Network offline or timeout
      return AssessmentOutcome.queued(queueId: queueId);
    }
  }

  /// Retry all pending assessments (call when app regains connectivity)
  Future<int> syncPendingAssessments() async {
    final pending = await LocalDbService.getPendingAssessments();
    int synced = 0;

    for (final row in pending) {
      try {
        final requestMap =
            jsonDecode(row['request_json'] as String) as Map<String, dynamic>;

        final request = _requestFromJson(requestMap);
        final result = await _api.predict(request);

        await LocalDbService.saveAssessmentResult(
          queueId: row['id'] as int,
          result: result,
        );
        synced++;
      } catch (_) {
        await LocalDbService.markAssessmentFailed(row['id'] as int);
      }
    }
    return synced;
  }

  PPHPredictionRequest _requestFromJson(Map<String, dynamic> json) {
    final c = json['clinical'] as Map<String, dynamic>;
    final a = json['anemia_features'] as Map<String, dynamic>;
    final p = json['ppg_features'] as Map<String, dynamic>?;

    return PPHPredictionRequest(
      patientLocalId: json['patient_local_id'] as String,
      visitId: json['visit_id'] as String,
      clinical: ClinicalInput(
        age: (c['age'] as num).toDouble(),
        systolicBp: (c['systolic_bp'] as num).toDouble(),
        diastolicBp: (c['diastolic_bp'] as num).toDouble(),
        heartRate: (c['heart_rate'] as num?)?.toDouble(),
        bloodSugar: (c['blood_sugar'] as num?)?.toDouble(),
        bmi: (c['bmi'] as num?)?.toDouble(),
        prevComplications: (c['prev_complications'] as int?) ?? 0,
        preexistDiabetes: (c['preexist_diabetes'] as int?) ?? 0,
        gestDiabetes: (c['gest_diabetes'] as int?) ?? 0,
        mentalHealth: (c['mental_health'] as int?) ?? 0,
      ),
      anemiaFeatures: AnemiaFeaturesInput(
        redPixelPct: (a['red_pixel_pct'] as num).toDouble(),
        greenPixelPct: (a['green_pixel_pct'] as num).toDouble(),
        bluePixelPct: (a['blue_pixel_pct'] as num).toDouble(),
        rgbSum: (a['rgb_sum'] as num).toDouble(),
        redGreenRatio: (a['red_green_ratio'] as num).toDouble(),
        pallorIndex: (a['pallor_index'] as num).toDouble(),
      ),
      ppgFeatures: p == null
          ? null
          : PPGFeaturesInput(
              hrBpmEst: (p['hr_bpm_est'] as num?)?.toDouble(),
              ibiMean: (p['ibi_mean'] as num?)?.toDouble(),
              ibiStd: (p['ibi_std'] as num?)?.toDouble(),
              peakCount: (p['peak_count'] as num?)?.toDouble(),
              ppgAmpMean: (p['ppg_amp_mean'] as num?)?.toDouble(),
              ppgAmpStd: (p['ppg_amp_std'] as num?)?.toDouble(),
              signalQuality: (p['signal_quality'] as num?)?.toDouble(),
            ),
    );
  }
}

// OUTCOME

enum AssessmentStatus { online, queued, failed }

class AssessmentOutcome {
  final AssessmentStatus status;
  final int queueId;
  final PPHPredictionResult? result;
  final String? error;

  const AssessmentOutcome._({
    required this.status,
    required this.queueId,
    this.result,
    this.error,
  });

  factory AssessmentOutcome.online({
    required int queueId,
    required PPHPredictionResult result,
  }) =>
      AssessmentOutcome._(
          status: AssessmentStatus.online,
          queueId: queueId,
          result: result);

  factory AssessmentOutcome.queued({required int queueId}) =>
      AssessmentOutcome._(
          status: AssessmentStatus.queued, queueId: queueId);

  factory AssessmentOutcome.failed(
          {required int queueId, required String error}) =>
      AssessmentOutcome._(
          status: AssessmentStatus.failed,
          queueId: queueId,
          error: error);

  bool get hasResult => result != null;
  bool get isPending => status == AssessmentStatus.queued;
}