import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://pph-proxy-prediction-fastapi.onrender.com';

// REQUEST MODELS

class ClinicalInput {
  final double age;
  final double systolicBp;
  final double diastolicBp;
  final double? bloodSugar;
  final double? bmi;
  final int prevComplications;
  final int preexistDiabetes;
  final int gestDiabetes;
  final int mentalHealth;
  final double? heartRate;

  const ClinicalInput({
    required this.age,
    required this.systolicBp,
    required this.diastolicBp,
    this.bloodSugar,
    this.bmi,
    this.prevComplications = 0,
    this.preexistDiabetes = 0,
    this.gestDiabetes = 0,
    this.mentalHealth = 0,
    this.heartRate,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        if (bloodSugar != null) 'blood_sugar': bloodSugar,
        if (bmi != null) 'bmi': bmi,
        'prev_complications': prevComplications,
        'preexist_diabetes': preexistDiabetes,
        'gest_diabetes': gestDiabetes,
        'mental_health': mentalHealth,
        if (heartRate != null) 'heart_rate': heartRate,
      };
}

class AnemiaFeaturesInput {
  final double redPixelPct;
  final double greenPixelPct;
  final double bluePixelPct;
  final double rgbSum;
  final double redGreenRatio;
  final double pallorIndex;

  const AnemiaFeaturesInput({
    required this.redPixelPct,
    required this.greenPixelPct,
    required this.bluePixelPct,
    required this.rgbSum,
    required this.redGreenRatio,
    required this.pallorIndex,
  });

  Map<String, dynamic> toJson() => {
        'red_pixel_pct': redPixelPct,
        'green_pixel_pct': greenPixelPct,
        'blue_pixel_pct': bluePixelPct,
        'rgb_sum': rgbSum,
        'red_green_ratio': redGreenRatio,
        'pallor_index': pallorIndex,
      };
}

class PPGFeaturesInput {
  final double? hrBpmEst;
  final double? ibiMean;
  final double? ibiStd;
  final double? peakCount;
  final double? ppgAmpMean;
  final double? ppgAmpStd;
  final double? signalQuality;

  const PPGFeaturesInput({
    this.hrBpmEst,
    this.ibiMean,
    this.ibiStd,
    this.peakCount,
    this.ppgAmpMean,
    this.ppgAmpStd,
    this.signalQuality,
  });

  Map<String, dynamic> toJson() => {
        if (hrBpmEst != null) 'hr_bpm_est': hrBpmEst,
        if (ibiMean != null) 'ibi_mean': ibiMean,
        if (ibiStd != null) 'ibi_std': ibiStd,
        if (peakCount != null) 'peak_count': peakCount,
        if (ppgAmpMean != null) 'ppg_amp_mean': ppgAmpMean,
        if (ppgAmpStd != null) 'ppg_amp_std': ppgAmpStd,
        if (signalQuality != null) 'signal_quality': signalQuality,
      };
}

class PPHPredictionRequest {
  final String patientLocalId;
  final String visitId;
  final ClinicalInput clinical;
  final AnemiaFeaturesInput anemiaFeatures;
  final PPGFeaturesInput? ppgFeatures;

  const PPHPredictionRequest({
    required this.patientLocalId,
    required this.visitId,
    required this.clinical,
    required this.anemiaFeatures,
    this.ppgFeatures,
  });

  Map<String, dynamic> toJson() => {
        'patient_local_id': patientLocalId,
        'visit_id': visitId,
        'clinical': clinical.toJson(),
        'anemia_features': anemiaFeatures.toJson(),
        if (ppgFeatures != null) 'ppg_features': ppgFeatures!.toJson(),
        'device_meta': {
          'app_version': '1.0.0',
          'model_request_mode': 'online',
        },
      };
}

// RESPONSE MODELS

enum RiskBand { low, moderate, high, unknown }

class PPHPrediction {
  final double pphProxyProbability;
  final int pphProxyLabel;
  final double thresholdUsed;
  final RiskBand riskBand;
  final double? baseModelProbability;

  const PPHPrediction({
    required this.pphProxyProbability,
    required this.pphProxyLabel,
    required this.thresholdUsed,
    required this.riskBand,
    this.baseModelProbability,
  });

  factory PPHPrediction.fromJson(Map<String, dynamic> json) {
    final bandStr = (json['risk_band'] ?? '').toString().toLowerCase();
    final band = bandStr == 'high'
        ? RiskBand.high
        : bandStr == 'moderate'
            ? RiskBand.moderate
            : bandStr == 'low'
                ? RiskBand.low
                : RiskBand.unknown;

    return PPHPrediction(
      pphProxyProbability:
          (json['pph_proxy_probability'] ?? 0.0).toDouble(),
      pphProxyLabel: (json['pph_proxy_label'] ?? 0) as int,
      thresholdUsed: (json['threshold_used'] ?? 0.5).toDouble(),
      riskBand: band,
      baseModelProbability:
          json['base_model_probability']?.toDouble(),
    );
  }

  bool get isHigh => riskBand == RiskBand.high;
  bool get isModerate => riskBand == RiskBand.moderate;
  bool get isLow => riskBand == RiskBand.low;

  String get riskLabel {
    switch (riskBand) {
      case RiskBand.high:
        return 'HIGH RISK';
      case RiskBand.moderate:
        return 'MODERATE RISK';
      case RiskBand.low:
        return 'LOW RISK';
      default:
        return 'UNKNOWN';
    }
  }

  String get clinicalGuidance {
    switch (riskBand) {
      case RiskBand.high:
        return 'Repeat vitals immediately. Assess active bleeding signs. Escalate per PPH protocol. Do not leave patient unattended.';
      case RiskBand.moderate:
        return 'Increased monitoring required. Re-check vitals in 15 minutes. Prepare IV access. Alert senior clinician.';
      case RiskBand.low:
        return 'Continue standard postpartum monitoring. Reassess in 30 minutes or sooner if symptoms change.';
      default:
        return 'Awaiting prediction. Continue standard monitoring.';
    }
  }

  String get probabilityPercent =>
      '${(pphProxyProbability * 100).toStringAsFixed(1)}%';
}

class PPHPredictionResult {
  final String status;
  final PPHPrediction prediction;
  final Map<String, dynamic> modelInfo;
  final List<String> warnings;

  const PPHPredictionResult({
    required this.status,
    required this.prediction,
    required this.modelInfo,
    required this.warnings,
  });

  factory PPHPredictionResult.fromJson(Map<String, dynamic> json) {
    return PPHPredictionResult(
      status: json['status'] ?? 'unknown',
      prediction: PPHPrediction.fromJson(
          json['prediction'] as Map<String, dynamic>),
      modelInfo: (json['model_info'] as Map<String, dynamic>?) ?? {},
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  String get modelVersion =>
      modelInfo['fusion_model_version']?.toString() ?? 'unknown';
  bool get isCalibrated => modelInfo['calibrated'] == true;
}

// SERVICE

class PPHPredictionService {
  static const Duration _timeout = Duration(seconds: 20);

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/model-info'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<PPHPredictionResult> predict(PPHPredictionRequest request) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/predictions/pph-proxy'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return PPHPredictionResult.fromJson(data);
    } else {
      final body = response.body;
      throw PPHApiException(
        statusCode: response.statusCode,
        message: _parseError(body),
      );
    }
  }

  String _parseError(String body) {
    try {
      final data = json.decode(body);
      return data['detail']?.toString() ?? 'Prediction failed';
    } catch (_) {
      return 'Server error (${body.length > 100 ? body.substring(0, 100) : body})';
    }
  }
}

class PPHApiException implements Exception {
  final int statusCode;
  final String message;

  const PPHApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'PPHApiException($statusCode): $message';
}