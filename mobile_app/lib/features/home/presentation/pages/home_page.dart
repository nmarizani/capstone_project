import 'package:flutter/material.dart';
import '../../../patient_intake/presentation/pages/patient_intake_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruvimbo Motherhood'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            _quickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.cloud_done, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text('Prediction service connected.')),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Start New Assessment'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientIntakePage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('PPG Capture (Coming Next)'),
            onPressed: null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Eye Capture Anemia (Coming Next)'),
            onPressed: null,
          ),
        ),
      ],
    );
  }
}