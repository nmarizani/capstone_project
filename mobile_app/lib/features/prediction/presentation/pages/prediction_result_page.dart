import 'package:flutter/material.dart';
import '../../data/models/fusion_prediction_response.dart';

class PredictionResultPage extends StatelessWidget {
  final FusionPredictionResponse response;

  const PredictionResultPage({
    super.key,
    required this.response,
  });

  Color _riskColor(String band) {
    switch (band.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.amber.shade700;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = response.prediction;
    final riskColor = _riskColor(p.riskBand);

    return Scaffold(
      appBar: AppBar(title: const Text('Prediction Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: riskColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.riskBand.toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('PPH Proxy Probability: ${p.pphProxyProbability.toStringAsFixed(4)}'),
                  Text('Threshold Used: ${p.thresholdUsed.toStringAsFixed(4)}'),
                  Text('Label: ${p.pphProxyLabel}'),
                  if (p.baseModelProbability != null)
                    Text('Base Model Probability: ${p.baseModelProbability!.toStringAsFixed(4)}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          _sectionCard(
            title: 'Explanations',
            icon: Icons.info_outline,
            items: response.explanations,
            emptyText: 'No explanations returned.',
          ),

          const SizedBox(height: 12),
          _sectionCard(
            title: 'Recommended Actions',
            icon: Icons.medical_services_outlined,
            items: response.recommendedActions,
            emptyText: 'No actions returned.',
          ),

          const SizedBox(height: 12),
          _sectionCard(
            title: 'Warnings',
            icon: Icons.warning_amber_rounded,
            items: response.warnings,
            emptyText: 'No warnings.',
          ),

          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.memory_outlined),
              title: const Text('Model Info'),
              subtitle: Text(
                'Version: ${response.modelInfo['fusion_model_version'] ?? 'unknown'}\n'
                    'Label Type: ${response.modelInfo['label_type'] ?? 'unknown'}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required String emptyText,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(emptyText)
            else
              ...items.map(
                    (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(e)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}