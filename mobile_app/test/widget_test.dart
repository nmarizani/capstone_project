// test/widget_test.dart
//
// Run all tests:   flutter test
// Run one group:   flutter test --name "LoginScreen"
// Run with coverage: flutter test --coverage
//
// NOTE: Screens that require Firebase (login submit, signup submit) are tested
// for UI rendering and validation only — actual Firebase calls are not made
// in widget tests. Use integration_test/ for full end-to-end flows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/home_pages/welcome_page.dart';
import 'package:mobile_app/features/auth/login_page.dart';
import 'package:mobile_app/features/auth/signup_page.dart';
import 'package:mobile_app/features/auth/set_password_page.dart';
import 'package:mobile_app/features/home_pages/notification_page.dart';
import 'package:mobile_app/features/settings_privacy/privacy_policy_page.dart';
import 'package:mobile_app/features/prediction/assessment_input_page.dart';
import 'package:mobile_app/features/prediction/assessment_result_page.dart';
import 'package:mobile_app/features/prediction/pph_prediction_service.dart';
import 'package:mobile_app/features/prediction/assessment_repository.dart';
import 'package:mobile_app/features/theme/app_theme.dart';

// HELPERS

/// Wraps a widget in MaterialApp with the app theme
Widget wrap(Widget w) => MaterialApp(theme: AppTheme.theme, home: w);

/// Wraps with a Navigator stack (needed for screens that call Navigator.pop)
Widget wrapNav(Widget w) => MaterialApp(
      theme: AppTheme.theme,
      home: w,
      routes: {'/welcome': (_) => const WelcomeScreen()},
    );

// THEME

group('AppColors', () {
  test('primary is #FF22F0', () {
    expect(AppColors.primary.value, 0xFFFF22F0);
  });

  test('secondary is #CAD6FF', () {
    expect(AppColors.secondary.value, 0xFFCAD6FF);
  });

  test('danger is red', () {
    expect(AppColors.danger.value, 0xFFFF3B30);
  });

  test('success is green', () {
    expect(AppColors.success.value, 0xFF4CAF50);
  });

  test('warning is yellow', () {
    expect(AppColors.warning.value, 0xFFFFD700);
  });
});

// PPH PREDICTION MODELS

group('RiskBand parsing', () {
  PPHPrediction _pred(String band) => PPHPrediction.fromJson({
        'pph_proxy_probability': 0.5,
        'pph_proxy_label': 1,
        'threshold_used': 0.25,
        'risk_band': band,
      });

  test('parses high', () {
    expect(_pred('high').riskBand, RiskBand.high);
    expect(_pred('high').isHigh, isTrue);
  });

  test('parses moderate', () {
    expect(_pred('moderate').riskBand, RiskBand.moderate);
    expect(_pred('moderate').isModerate, isTrue);
  });

  test('parses low', () {
    expect(_pred('low').riskBand, RiskBand.low);
    expect(_pred('low').isLow, isTrue);
  });

  test('unknown band falls back to RiskBand.unknown', () {
    expect(_pred('anything_else').riskBand, RiskBand.unknown);
  });

  test('riskLabel is uppercase', () {
    expect(_pred('high').riskLabel, 'HIGH RISK');
    expect(_pred('moderate').riskLabel, 'MODERATE RISK');
    expect(_pred('low').riskLabel, 'LOW RISK');
  });

  test('probabilityPercent formats to 1 decimal place', () {
    final pred = PPHPrediction.fromJson({
      'pph_proxy_probability': 0.783,
      'pph_proxy_label': 1,
      'threshold_used': 0.25,
      'risk_band': 'high',
    });
    expect(pred.probabilityPercent, '78.3%');
  });

  test('clinicalGuidance is non-empty for all valid bands', () {
    for (final b in ['high', 'moderate', 'low']) {
      expect(_pred(b).clinicalGuidance, isNotEmpty);
    }
  });
});

group('ClinicalInput.toJson', () {
  test('required fields are always present', () {
    final json = ClinicalInput(
      age: 28,
      systolicBp: 120,
      diastolicBp: 80,
    ).toJson();

    expect(json['age'], 28.0);
    expect(json['systolic_bp'], 120.0);
    expect(json['diastolic_bp'], 80.0);
    expect(json['prev_complications'], 0);
    expect(json['preexist_diabetes'], 0);
  });

  test('null optional fields are omitted', () {
    final json = ClinicalInput(
      age: 25,
      systolicBp: 110,
      diastolicBp: 70,
    ).toJson();

    expect(json.containsKey('blood_sugar'), isFalse);
    expect(json.containsKey('bmi'), isFalse);
    expect(json.containsKey('heart_rate'), isFalse);
  });

  test('boolean risk flags become integers', () {
    final json = ClinicalInput(
      age: 30,
      systolicBp: 100,
      diastolicBp: 65,
      prevComplications: 1,
      preexistDiabetes: 1,
    ).toJson();

    expect(json['prev_complications'], 1);
    expect(json['preexist_diabetes'], 1);
    expect(json['gest_diabetes'], 0);
  });
});

group('AnemiaFeaturesInput.toJson', () {
  test('all 6 fields are present', () {
    final json = const AnemiaFeaturesInput(
      redPixelPct: 0.41,
      greenPixelPct: 0.33,
      bluePixelPct: 0.26,
      rgbSum: 1.0,
      redGreenRatio: 1.24,
      pallorIndex: 0.37,
    ).toJson();

    expect(json['red_pixel_pct'], 0.41);
    expect(json['green_pixel_pct'], 0.33);
    expect(json['blue_pixel_pct'], 0.26);
    expect(json['rgb_sum'], 1.0);
    expect(json['red_green_ratio'], 1.24);
    expect(json['pallor_index'], 0.37);
  });
});

group('PPGFeaturesInput.toJson', () {
  test('empty PPG produces empty map', () {
    expect(const PPGFeaturesInput().toJson(), isEmpty);
  });

  test('only provided fields appear', () {
    final json =
        const PPGFeaturesInput(hrBpmEst: 102, peakCount: 7).toJson();
    expect(json['hr_bpm_est'], 102.0);
    expect(json['peak_count'], 7.0);
    expect(json.containsKey('ibi_mean'), isFalse);
  });
});

group('PPHPredictionRequest.toJson', () {
  final req = PPHPredictionRequest(
    patientLocalId: 'PT-001',
    visitId: 'visit-001',
    clinical: const ClinicalInput(
        age: 28, systolicBp: 120, diastolicBp: 80),
    anemiaFeatures: const AnemiaFeaturesInput(
      redPixelPct: 0.41,
      greenPixelPct: 0.33,
      bluePixelPct: 0.26,
      rgbSum: 1.0,
      redGreenRatio: 1.24,
      pallorIndex: 0.37,
    ),
  );

  test('top-level keys are correct', () {
    final json = req.toJson();
    expect(json['patient_local_id'], 'PT-001');
    expect(json['visit_id'], 'visit-001');
    expect(json['clinical'], isA<Map>());
    expect(json['anemia_features'], isA<Map>());
    expect(json['device_meta']['app_version'], '1.0.0');
  });

  test('ppg_features absent when null', () {
    expect(req.toJson().containsKey('ppg_features'), isFalse);
  });

  test('ppg_features present when provided', () {
    final withPpg = PPHPredictionRequest(
      patientLocalId: 'PT-001',
      visitId: 'v-001',
      clinical: const ClinicalInput(
          age: 28, systolicBp: 120, diastolicBp: 80),
      anemiaFeatures: const AnemiaFeaturesInput(
        redPixelPct: 0.4,
        greenPixelPct: 0.3,
        bluePixelPct: 0.3,
        rgbSum: 1.0,
        redGreenRatio: 1.2,
        pallorIndex: 0.35,
      ),
      ppgFeatures: const PPGFeaturesInput(hrBpmEst: 102),
    );
    expect(withPpg.toJson().containsKey('ppg_features'), isTrue);
  });
});

group('PPHPredictionResult parsing', () {
  test('parses full API response correctly', () {
    final result = PPHPredictionResult.fromJson({
      'status': 'ok',
      'prediction': {
        'pph_proxy_probability': 0.78,
        'pph_proxy_label': 1,
        'threshold_used': 0.25,
        'risk_band': 'high',
        'base_model_probability': 0.81,
      },
      'model_info': {
        'fusion_model_version': '20260222_201040',
        'label_type': 'proxy_rule_v1',
        'calibrated': true,
        'n_features_expected': 64,
      },
      'warnings': ['Missing 3 features'],
    });

    expect(result.status, 'ok');
    expect(result.prediction.isHigh, isTrue);
    expect(result.modelVersion, '20260222_201040');
    expect(result.isCalibrated, isTrue);
    expect(result.warnings, hasLength(1));
  });

  test('handles missing optional fields gracefully', () {
    final result = PPHPredictionResult.fromJson({
      'status': 'ok',
      'prediction': {
        'pph_proxy_probability': 0.2,
        'pph_proxy_label': 0,
        'threshold_used': 0.25,
        'risk_band': 'low',
      },
    });

    expect(result.modelVersion, 'unknown');
    expect(result.warnings, isEmpty);
    expect(result.isCalibrated, isFalse);
  });
});

group('AssessmentOutcome', () {
  final mockResult = PPHPredictionResult.fromJson({
    'status': 'ok',
    'prediction': {
      'pph_proxy_probability': 0.78,
      'pph_proxy_label': 1,
      'threshold_used': 0.25,
      'risk_band': 'high',
    },
  });

  test('online outcome has result and is not pending', () {
    final o = AssessmentOutcome.online(queueId: 1, result: mockResult);
    expect(o.hasResult, isTrue);
    expect(o.isPending, isFalse);
    expect(o.status, AssessmentStatus.online);
  });

  test('queued outcome is pending with no result', () {
    final o = AssessmentOutcome.queued(queueId: 2);
    expect(o.hasResult, isFalse);
    expect(o.isPending, isTrue);
    expect(o.status, AssessmentStatus.queued);
  });

  test('failed outcome carries error string', () {
    final o = AssessmentOutcome.failed(queueId: 3, error: 'Timeout');
    expect(o.error, 'Timeout');
    expect(o.hasResult, isFalse);
    expect(o.status, AssessmentStatus.failed);
  });
});

// WELCOME SCREEN

group('WelcomeScreen', () {
  testWidgets('shows Ruvimbo and Motherhood text', (tester) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('Ruvimbo'), findsOneWidget);
    expect(find.text('Motherhood'), findsOneWidget);
  });

  testWidgets('shows tagline', (tester) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('Postpartum hemorrhage early\ndetection system'),
        findsOneWidget);
  });

  testWidgets('shows Log In and Sign Up buttons', (tester) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
});

// LOGIN SCREEN

group('LoginScreen', () {
  testWidgets('renders title and form fields', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump();
    expect(find.text('Log In'), findsWidgets);
    // ID hint text
    expect(find.text('101909102920101'), findsOneWidget);
  });

  testWidgets('shows Forgot Password link', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump();
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('shows Sign Up link', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump();
    expect(find.text('New User? '), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets);
  });

  testWidgets('shows validation errors when submitted empty', (tester) async {
    await tester.pumpWidget(wrapNav(const LoginScreen()));
    await tester.pump();

    // Tap the Log In submit button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pump();

    expect(find.text('Please enter your ID number'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('password field is obscured by default', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump();
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    // Password is the second TextField
    expect(fields[1].obscureText, isTrue);
  });
});

// SIGNUP SCREEN

group('SignUpScreen', () {
  testWidgets('shows all three input fields', (tester) async {
    await tester.pumpWidget(wrap(const SignUpScreen()));
    await tester.pump();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('ID Number'), findsOneWidget);
    expect(find.text('Station ID Number'), findsOneWidget);
  });

  testWidgets('shows Terms and Privacy Policy links', (tester) async {
    await tester.pumpWidget(wrap(const SignUpScreen()));
    await tester.pump();
    expect(find.textContaining('Terms of Use'), findsOneWidget);
    expect(find.textContaining('Privacy Policy'), findsOneWidget);
  });

  testWidgets('shows validation error when submitted empty', (tester) async {
    await tester.pumpWidget(wrapNav(const SignUpScreen()));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pump();

    expect(find.text('Please enter your full name'), findsOneWidget);
  });
});

// SET PASSWORD SCREEN

group('SetPasswordScreen', () {
  Widget buildScreen() => wrap(const SetPasswordScreen(
        fullName: 'Tinevimbo Muyayagwa',
        idNumber: '101909102920101',
        stationIdNumber: '506070',
      ));

  testWidgets('shows user name and ID in card', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Tinevimbo Muyayagwa'), findsOneWidget);
    expect(find.text('ID: 101909102920101'), findsOneWidget);
  });

  testWidgets('shows Confirm Station Password label', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Confirm Station Password'), findsOneWidget);
  });

  testWidgets('shows mismatch error when passwords differ', (tester) async {
    await tester.pumpWidget(wrapNav(buildScreen()));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password1');
    await tester.enterText(fields.at(1), 'different2');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create New Password'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('shows short password error', (tester) async {
    await tester.pumpWidget(wrapNav(buildScreen()));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), '123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create New Password'));
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
});

// LOGOUT SCREEN

group('LogoutScreen', () {
  testWidgets('shows Logout title', (tester) async {
    await tester.pumpWidget(wrap(const LogoutScreen()));
    await tester.pump();
    expect(find.text('Logout'), findsWidgets);
  });

  testWidgets('shows Cancel and Yes Logout buttons', (tester) async {
    await tester.pumpWidget(wrap(const LogoutScreen()));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Yes, Logout'), findsOneWidget);
  });

  testWidgets('shows Midwife label', (tester) async {
    await tester.pumpWidget(wrap(const LogoutScreen()));
    await tester.pump();
    expect(find.text('Midwife'), findsOneWidget);
  });

  testWidgets('shows local data preservation notice', (tester) async {
    await tester.pumpWidget(wrap(const LogoutScreen()));
    await tester.pump();
    expect(find.text('Local data is preserved after logout'), findsOneWidget);
  });

  testWidgets('shows unsynced data message', (tester) async {
    await tester.pumpWidget(wrap(const LogoutScreen()));
    await tester.pump();
    expect(
        find.textContaining('unsynced assessments'), findsOneWidget);
  });
});

// NOTIFICATIONS SCREEN

group('NotificationsScreen', () {
  testWidgets('shows Notifications header', (tester) async {
    await tester.pumpWidget(wrap(const NotificationsScreen()));
    await tester.pump();
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('shows all three risk categories', (tester) async {
    await tester.pumpWidget(wrap(const NotificationsScreen()));
    await tester.pump();
    expect(find.text('Critical Range Patients'), findsOneWidget);
    expect(find.text('Warning Range Patients'), findsOneWidget);
    expect(find.text('Normal Range Patients'), findsOneWidget);
  });
});

// PRIVACY POLICY SCREEN

group('PrivacyPolicyScreen', () {
  testWidgets('shows Privacy Policy title', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyPolicyScreen()));
    await tester.pump();
    expect(find.text('Privacy Policy'), findsWidgets);
  });

  testWidgets('shows Terms and Conditions section', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyPolicyScreen()));
    await tester.pump();
    expect(find.text('Terms & Conditions'), findsOneWidget);
  });

  testWidgets('shows Last Update date', (tester) async {
    await tester.pumpWidget(wrap(const PrivacyPolicyScreen()));
    await tester.pump();
    expect(find.text('Last Update: 28/01/2026'), findsOneWidget);
  });
});

// ASSESSMENT INPUT SCREEN

group('AssessmentInputScreen', () {
  Widget buildScreen() => wrap(const AssessmentInputScreen(
        patientLocalId: 'PT-TEST-001',
        patientName: 'Test Patient',
      ));

  testWidgets('shows PPH Assessment title', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('PPH Assessment'), findsOneWidget);
  });

  testWidgets('shows patient name in subtitle', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Test Patient'), findsOneWidget);
  });

  testWidgets('shows all three tabs', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Clinical'), findsOneWidget);
    expect(find.text('Anemia'), findsOneWidget);
    expect(find.text('PPG'), findsOneWidget);
  });

  testWidgets('shows Run PPH Assessment button', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Run PPH Assessment'), findsOneWidget);
  });

  testWidgets('Clinical tab shows Vital Signs section', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Vital Signs'), findsOneWidget);
  });

  testWidgets('Clinical tab shows Risk Factors section', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    expect(find.text('Risk Factors'), findsOneWidget);
  });

  testWidgets('shows validation error if required fields empty', (tester) async {
    await tester.pumpWidget(wrapNav(buildScreen()));
    await tester.pump();

    await tester.tap(find.text('Run PPH Assessment'));
    await tester.pump();

    // Should show snackbar or inline validation
    expect(
      find.byType(SnackBar).evaluate().isNotEmpty ||
          find.text('Required').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('can switch to Anemia tab', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();

    await tester.tap(find.text('Anemia'));
    await tester.pumpAndSettle();

    expect(find.text('RGB Pallor Features'), findsOneWidget);
  });

  testWidgets('can switch to PPG tab', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();

    await tester.tap(find.text('PPG'));
    await tester.pumpAndSettle();

    expect(find.text('PPG Waveform Features'), findsOneWidget);
  });
});

// ASSESSMENT RESULT SCREEN

group('AssessmentResultScreen — online result', () {
  final highResult = PPHPredictionResult.fromJson({
    'status': 'ok',
    'prediction': {
      'pph_proxy_probability': 0.82,
      'pph_proxy_label': 1,
      'threshold_used': 0.25,
      'risk_band': 'high',
    },
    'model_info': {
      'fusion_model_version': '20260222_201040',
      'label_type': 'proxy_rule_v1',
      'calibrated': true,
    },
    'warnings': [],
  });

  testWidgets('shows HIGH RISK label', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('HIGH RISK'), findsOneWidget);
  });

  testWidgets('shows probability percentage', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('82.0%'), findsOneWidget);
  });

  testWidgets('shows patient name', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('Test Patient'), findsOneWidget);
  });

  testWidgets('shows Clinical Guidance section', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('Clinical Guidance'), findsOneWidget);
  });

  testWidgets('shows Model Status disclaimer', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('Model Status'), findsOneWidget);
  });

  testWidgets('shows Back to Dashboard button', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.online(queueId: 1, result: highResult),
    )));
    await tester.pump();
    expect(find.text('Back to Dashboard'), findsOneWidget);
  });
});

group('AssessmentResultScreen — offline/queued', () {
  testWidgets('shows Prediction Pending Sync when queued', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.queued(queueId: 2),
    )));
    await tester.pump();
    expect(find.text('Prediction Pending Sync'), findsOneWidget);
  });

  testWidgets('shows manual triage protocol when offline', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.queued(queueId: 2),
    )));
    await tester.pump();
    expect(find.text('Manual Triage Protocol'), findsOneWidget);
  });
});

group('AssessmentResultScreen - failed', () {
  testWidgets('shows Prediction Failed on error', (tester) async {
    await tester.pumpWidget(wrap(AssessmentResultScreen(
      patientName: 'Test Patient',
      outcome: AssessmentOutcome.failed(
          queueId: 3, error: 'Server unavailable'),
    )));
    await tester.pump();
    expect(find.text('Prediction Failed'), findsOneWidget);
    expect(find.text('Server unavailable'), findsOneWidget);
  });
});