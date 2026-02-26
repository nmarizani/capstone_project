import 'package:flutter/material.dart';
import 'assessment_repository.dart';
import 'pph_prediction_service.dart';
import '../theme/app_theme.dart';

class AssessmentResultScreen extends StatelessWidget {
  final String patientName;
  final AssessmentOutcome outcome;

  const AssessmentResultScreen({
    super.key,
    required this.patientName,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assessment Result',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: outcome.status == AssessmentStatus.queued
              ? _buildOfflineState(context)
              : outcome.status == AssessmentStatus.failed
                  ? _buildFailedState(context)
                  : _buildResultState(context, outcome.result!),
        ),
      ),
    );
  }

  // OFFLINE / QUEUED

  Widget _buildOfflineState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_outlined,
                    color: Colors.orange, size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'Prediction Pending Sync',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No network connection detected. Assessment data has been saved locally and will be submitted automatically when connectivity is restored.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textLight, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              _infoRow(
                  Icons.save_outlined, 'Data saved locally', Colors.green),
              _infoRow(Icons.sync_outlined, 'Will auto-sync when online',
                  Colors.orange),
              _infoRow(Icons.monitor_heart_outlined,
                  'Continue standard monitoring', AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildManualTriageCard(),
      ],
    );
  }

  // FAILED RESULT

  Widget _buildFailedState(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.danger.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'Prediction Failed',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                outcome.error ?? 'Server error. Please retry.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildManualTriageCard(),
      ],
    );
  }

  // SUCCESS RESULT

  Widget _buildResultState(
      BuildContext context, PPHPredictionResult result) {
    final pred = result.prediction;
    final riskColor = _riskColor(pred.riskBand);

    return Column(
      children: [
        // Main risk card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: riskColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Patient name
              Text(
                patientName,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Risk indicator dot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pred.riskLabel,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Probability circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor.withOpacity(0.08),
                  border: Border.all(color: riskColor, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pred.probabilityPercent,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                      const Text(
                        'risk score',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shock index
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Threshold: ${pred.thresholdUsed.toStringAsFixed(3)}',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Clinical guidance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: riskColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      color: riskColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Clinical Guidance',
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pred.clinicalGuidance,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Model disclaimer (important for clinical safety)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Model Status',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'This is a proxy-supervised prediction (pph_proxy_v1), not a confirmed clinical diagnosis. Use as a decision-support tool alongside clinical judgment.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _pillBadge(
                      'v${result.modelVersion}', AppColors.secondary),
                  const SizedBox(width: 8),
                  if (result.isCalibrated)
                    _pillBadge('Calibrated', Colors.green.shade100),
                  const SizedBox(width: 8),
                  _pillBadge(
                      result.modelInfo['label_type']?.toString() ??
                          'proxy',
                      AppColors.primary.withOpacity(0.1)),
                ],
              ),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...result.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(
                                  color: Colors.orange, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Done button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.popUntil(context, (r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Back to Dashboard',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildManualTriageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_outlined,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Manual Triage Protocol',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _triageStep('1', 'Check vital signs (BP, HR, RR)'),
          _triageStep('2', 'Assess uterine tone and fundal height'),
          _triageStep('3', 'Estimate blood loss visually'),
          _triageStep('4', 'Alert senior clinician if concerned'),
          _triageStep('5', 'Document findings and time'),
        ],
      ),
    );
  }

  Widget _triageStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textDark, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _pillBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Color _riskColor(RiskBand band) {
    switch (band) {
      case RiskBand.high:
        return AppColors.danger;
      case RiskBand.moderate:
        return AppColors.warning;
      case RiskBand.low:
        return AppColors.success;
      default:
        return AppColors.textLight;
    }
  }
}