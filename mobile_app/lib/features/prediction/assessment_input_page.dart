import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pph_prediction_service.dart';
import 'assessment_repository.dart';
import '../theme/app_theme.dart';
import 'assessment_result_page.dart';

class AssessmentInputScreen extends StatefulWidget {
  final String patientLocalId;
  final String patientName;

  const AssessmentInputScreen({
    super.key,
    required this.patientLocalId,
    required this.patientName,
  });

  @override
  State<AssessmentInputScreen> createState() => _AssessmentInputScreenState();
}

class _AssessmentInputScreenState extends State<AssessmentInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;

  // Clinical fields
  final _ageCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _bloodSugarCtrl = TextEditingController();
  final _bmiCtrl = TextEditingController();
  bool _prevComplications = false;
  bool _preexistDiabetes = false;
  bool _gestDiabetes = false;
  bool _mentalHealth = false;

  // Anemia fields
  final _redPctCtrl = TextEditingController();
  final _greenPctCtrl = TextEditingController();
  final _bluePctCtrl = TextEditingController();
  final _rgbSumCtrl = TextEditingController(text: '1.0');
  final _redGreenRatioCtrl = TextEditingController();
  final _pallorIndexCtrl = TextEditingController();

  // PPG fields
  final _hrBpmCtrl = TextEditingController();
  final _ibiMeanCtrl = TextEditingController();
  final _ibiStdCtrl = TextEditingController();
  final _peakCountCtrl = TextEditingController();
  final _ppgAmpMeanCtrl = TextEditingController();
  final _ppgAmpStdCtrl = TextEditingController();
  final _signalQualityCtrl = TextEditingController();

  final _repo = AssessmentRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _ageCtrl, _systolicCtrl, _diastolicCtrl, _heartRateCtrl,
      _bloodSugarCtrl, _bmiCtrl, _redPctCtrl, _greenPctCtrl,
      _bluePctCtrl, _rgbSumCtrl, _redGreenRatioCtrl, _pallorIndexCtrl,
      _hrBpmCtrl, _ibiMeanCtrl, _ibiStdCtrl, _peakCountCtrl,
      _ppgAmpMeanCtrl, _ppgAmpStdCtrl, _signalQualityCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete required fields in all tabs'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final visitId =
        'visit_${DateTime.now().millisecondsSinceEpoch}';

    final clinical = ClinicalInput(
      age: double.parse(_ageCtrl.text),
      systolicBp: double.parse(_systolicCtrl.text),
      diastolicBp: double.parse(_diastolicCtrl.text),
      heartRate: _heartRateCtrl.text.isNotEmpty
          ? double.tryParse(_heartRateCtrl.text)
          : null,
      bloodSugar: _bloodSugarCtrl.text.isNotEmpty
          ? double.tryParse(_bloodSugarCtrl.text)
          : null,
      bmi: _bmiCtrl.text.isNotEmpty ? double.tryParse(_bmiCtrl.text) : null,
      prevComplications: _prevComplications ? 1 : 0,
      preexistDiabetes: _preexistDiabetes ? 1 : 0,
      gestDiabetes: _gestDiabetes ? 1 : 0,
      mentalHealth: _mentalHealth ? 1 : 0,
    );

    final anemia = AnemiaFeaturesInput(
      redPixelPct: double.parse(_redPctCtrl.text),
      greenPixelPct: double.parse(_greenPctCtrl.text),
      bluePixelPct: double.parse(_bluePctCtrl.text),
      rgbSum: double.tryParse(_rgbSumCtrl.text) ?? 1.0,
      redGreenRatio: double.parse(_redGreenRatioCtrl.text),
      pallorIndex: double.parse(_pallorIndexCtrl.text),
    );

    final hasPpg = _hrBpmCtrl.text.isNotEmpty ||
        _ibiMeanCtrl.text.isNotEmpty ||
        _peakCountCtrl.text.isNotEmpty;

    final ppg = hasPpg
        ? PPGFeaturesInput(
            hrBpmEst: double.tryParse(_hrBpmCtrl.text),
            ibiMean: double.tryParse(_ibiMeanCtrl.text),
            ibiStd: double.tryParse(_ibiStdCtrl.text),
            peakCount: double.tryParse(_peakCountCtrl.text),
            ppgAmpMean: double.tryParse(_ppgAmpMeanCtrl.text),
            ppgAmpStd: double.tryParse(_ppgAmpStdCtrl.text),
            signalQuality: double.tryParse(_signalQualityCtrl.text),
          )
        : null;

    final outcome = await _repo.submitAssessment(
      patientLocalId: widget.patientLocalId,
      visitId: visitId,
      clinical: clinical,
      anemiaFeatures: anemia,
      ppgFeatures: ppg,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(
          patientName: widget.patientName,
          outcome: outcome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'PPH Assessment',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            Text(
              widget.patientName,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Clinical', icon: Icon(Icons.medical_information_outlined, size: 18)),
            Tab(text: 'Anemia', icon: Icon(Icons.bloodtype_outlined, size: 18)),
            Tab(text: 'PPG', icon: Icon(Icons.monitor_heart_outlined, size: 18)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildClinicalTab(),
            _buildAnemiaTab(),
            _buildPpgTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitAssessment,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 20),
          label: Text(
            _isLoading ? 'Running Prediction...' : 'Run PPH Assessment',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildClinicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Vital Signs', Icons.favorite_outline),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _numField(_ageCtrl, 'Age (years)', required: true)),
            const SizedBox(width: 12),
            Expanded(child: _numField(_heartRateCtrl, 'Heart Rate (bpm)')),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_systolicCtrl, 'Systolic BP', required: true)),
            const SizedBox(width: 12),
            Expanded(child: _numField(_diastolicCtrl, 'Diastolic BP', required: true)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_bloodSugarCtrl, 'Blood Sugar (mg/dL)')),
            const SizedBox(width: 12),
            Expanded(child: _numField(_bmiCtrl, 'BMI')),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('Risk Factors', Icons.warning_amber_outlined),
          const SizedBox(height: 8),
          _toggleTile('Previous Complications', _prevComplications,
              (v) => setState(() => _prevComplications = v)),
          _toggleTile('Pre-existing Diabetes', _preexistDiabetes,
              (v) => setState(() => _preexistDiabetes = v)),
          _toggleTile('Gestational Diabetes', _gestDiabetes,
              (v) => setState(() => _gestDiabetes = v)),
          _toggleTile('Mental Health Conditions', _mentalHealth,
              (v) => setState(() => _mentalHealth = v)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnemiaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('RGB Pallor Features', Icons.colorize_outlined),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Derived from fingernail/conjunctiva image RGB analysis. Values between 0.0 and 1.0.',
              style: TextStyle(
                  color: AppColors.textLight, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_redPctCtrl, 'Red %', required: true)),
            const SizedBox(width: 12),
            Expanded(child: _numField(_greenPctCtrl, 'Green %', required: true)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_bluePctCtrl, 'Blue %', required: true)),
            const SizedBox(width: 12),
            Expanded(child: _numField(_rgbSumCtrl, 'RGB Sum')),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _numField(_redGreenRatioCtrl, 'Red/Green Ratio',
                    required: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _numField(_pallorIndexCtrl, 'Pallor Index',
                    required: true)),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPpgTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PPG Waveform Features', Icons.show_chart_outlined),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Derived from Arduino PPG sensor. All fields optional — leave blank if sensor data is unavailable.',
              style: TextStyle(
                  color: AppColors.textLight, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_hrBpmCtrl, 'HR Estimate (bpm)')),
            const SizedBox(width: 12),
            Expanded(child: _numField(_peakCountCtrl, 'Peak Count')),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_ibiMeanCtrl, 'IBI Mean (s)')),
            const SizedBox(width: 12),
            Expanded(child: _numField(_ibiStdCtrl, 'IBI Std (s)')),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numField(_ppgAmpMeanCtrl, 'Amplitude Mean')),
            const SizedBox(width: 12),
            Expanded(child: _numField(_ppgAmpStdCtrl, 'Amplitude Std')),
          ]),
          const SizedBox(height: 14),
          _numField(_signalQualityCtrl, 'Signal Quality (0-1)'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _toggleTile(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.inputBorder,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: value ? AppColors.primary : AppColors.textDark,
            fontWeight: value ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}