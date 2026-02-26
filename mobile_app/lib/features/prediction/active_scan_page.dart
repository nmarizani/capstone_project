import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../db/local_db_service.dart';
import 'assessment_repository.dart';
import 'assessment_input_page.dart';

class ActiveScanScreen extends StatefulWidget {
  const ActiveScanScreen({super.key});

  @override
  State<ActiveScanScreen> createState() => _ActiveScanScreenState();
}

class _ActiveScanScreenState extends State<ActiveScanScreen> {
  List<Map<String, dynamic>> _recentAssessments = [];
  bool _loading = true;

  // Demo patient — replace with real patient selection
  static const _demoPatient = {
    'local_id': 'PT-2026-0847',
    'name': 'Tinevimbo Muyayagwa',
    'status': 'Postpartum: 30 minutes',
  };

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final rows = await LocalDbService.getAssessmentsForPatient(
        _demoPatient['local_id']!);
    setState(() {
      _recentAssessments = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, Color(0xFFE0EAFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'PPG Monitoring',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Patient card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.secondary.withOpacity(0.3),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _demoPatient['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'ID: ${_demoPatient['local_id']}',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _demoPatient['status']!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PPG info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continuous Analysis',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'For early shock detection',
                  style:
                      TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
                const SizedBox(height: 14),
                // Waveform placeholder
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Icon(Icons.show_chart,
                        color: AppColors.primary, size: 36),
                  ),
                ),
                const SizedBox(height: 16),

                // Launch full assessment
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssessmentInputScreen(
                            patientLocalId: _demoPatient['local_id']!,
                            patientName: _demoPatient['name']!,
                          ),
                        ),
                      );
                      _loadRecent(); // refresh after returning
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 22),
                    label: const Text(
                      'Start PPH Assessment',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent assessments
          if (!_loading && _recentAssessments.isNotEmpty) ...[
            const Text(
              'Recent Assessments',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            ..._recentAssessments.take(3).map(_buildAssessmentRow),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentRow(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? 'pending';
    final band = row['risk_band'] as String?;
    final prob = row['probability'] as double?;
    final createdAt = row['created_at'] as String? ?? '';

    Color bandColor;
    switch (band) {
      case 'high':
        bandColor = AppColors.danger;
        break;
      case 'moderate':
        bandColor = AppColors.warning;
        break;
      case 'low':
        bandColor = AppColors.success;
        break;
      default:
        bandColor = AppColors.textLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bandColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: bandColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  band != null
                      ? '${band.toUpperCase()} RISK'
                      : status.toUpperCase(),
                  style: TextStyle(
                    color: bandColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  createdAt.length > 16
                      ? createdAt.substring(0, 16).replaceAll('T', ' ')
                      : createdAt,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          if (prob != null)
            Text(
              '${(prob * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: bandColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}