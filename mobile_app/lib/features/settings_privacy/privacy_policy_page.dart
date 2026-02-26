import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Update: 28/01/2026',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                'Privacy & Data Usage',
                'Ruvimbo collects PPG waveforms and clinical vitals solely to detect postpartum hemorrhage risk. We treat all maternal health data as strictly confidential, ensuring it is used only for its life-saving purpose and never shared with third parties.',
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Security & Offline Storage',
                'To support rural clinics, this app operates offline-first. All patient data and AI analysis are stored in encrypted local storage on the device. All clinical records is protected by end-to-end encryption, ensuring patient information remains secure and private even in areas with limited connectivity.',
              ),
              const SizedBox(height: 20),

              Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              _buildTerm(
                1,
                'Clinical Decision Support only. This app is monitoring/alert tool designed to provide health care providers with realtime risk assessments; it is not a replacement for professional clinical judgment or medical intervention.',
              ),
              _buildTerm(
                2,
                'Data Accuracy. Users are responsible for ensuring the Arduino sensor is placed correctly on the patient\'s finger, as improper placement may lead to inaccurate risk assessments.',
              ),
              _buildTerm(
                3,
                'Local Device Security. Since data is stored locally for offline use, users are responsible for securing the physical mobile device and preventing unauthorized access to patient records.',
              ),
              _buildTerm(
                4,
                'Hardware Maintenance. The Ruvimbo software is designed to work with specific Arduino-compatible hardware. Using unauthorized or damaged hardware sensors may compromise the safety and reliability of the monitoring.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTerm(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number.',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}