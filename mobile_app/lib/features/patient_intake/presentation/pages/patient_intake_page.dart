import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../prediction/presentation/bloc/prediction_bloc.dart';
import '../../../prediction/presentation/bloc/prediction_event.dart';
import '../../../prediction/presentation/bloc/prediction_state.dart';
import '../../../prediction/presentation/pages/prediction_result_page.dart';

class PatientIntakePage extends StatefulWidget {
  const PatientIntakePage({super.key});

  @override
  State<PatientIntakePage> createState() => _PatientIntakePageState();
}

class _PatientIntakePageState extends State<PatientIntakePage> {
  final _formKey = GlobalKey<FormState>();

  final _patientIdCtrl = TextEditingController(text: 'ZW-HRE-001');

  final _pAnemiaCtrl = TextEditingController(text: '0.81');
  final _prevCompCtrl = TextEditingController(text: '1');
  final _sbpCtrl = TextEditingController(text: '90');
  final _dbpCtrl = TextEditingController(text: '60');
  final _hrCtrl = TextEditingController(text: '112');
  final _signalQualityCtrl = TextEditingController(text: '0.88');

  String _visitId = const Uuid().v4();

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _pAnemiaCtrl.dispose();
    _prevCompCtrl.dispose();
    _sbpCtrl.dispose();
    _dbpCtrl.dispose();
    _hrCtrl.dispose();
    _signalQualityCtrl.dispose();
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0.0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final features = <String, double>{
      'p_anemia': _d(_pAnemiaCtrl),
      'prev_complications': _d(_prevCompCtrl),
      'systolic_bp': _d(_sbpCtrl),
      'diastolic_bp': _d(_dbpCtrl),
      'hr_bpm_est': _d(_hrCtrl),
      'signal_quality': _d(_signalQualityCtrl),
    };

    context.read<PredictionBloc>().add(
      SubmitPredictionRequested(
        patientLocalId: _patientIdCtrl.text.trim(),
        visitId: _visitId,
        features: features,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PredictionBloc, PredictionState>(
      listener: (context, state) {
        if (state.response != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PredictionResultPage(response: state.response!),
            ),
          );
        }

        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New Assessment')),
        body: BlocBuilder<PredictionBloc, PredictionState>(
          builder: (context, state) {
            return AbsorbPointer(
              absorbing: state.isLoading,
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Patient',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _patientIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Patient Local ID',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _visitId,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Visit ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Prediction Inputs (current API-ready fields)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        _numField(_pAnemiaCtrl, 'Anemia Probability (p_anemia)'),
                        const SizedBox(height: 8),
                        _numField(_prevCompCtrl, 'Previous Complications (0/1)'),
                        const SizedBox(height: 8),
                        _numField(_sbpCtrl, 'Systolic BP'),
                        const SizedBox(height: 8),
                        _numField(_dbpCtrl, 'Diastolic BP'),
                        const SizedBox(height: 8),
                        _numField(_hrCtrl, 'Heart Rate (estimated)'),
                        const SizedBox(height: 8),
                        _numField(_signalQualityCtrl, 'PPG Signal Quality (0-1)'),

                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Run Prediction'),
                        ),
                      ],
                    ),
                  ),
                  if (state.isLoading)
                    Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
        return null;
      },
    );
  }
}