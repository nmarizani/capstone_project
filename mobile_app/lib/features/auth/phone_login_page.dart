import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'phone_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../home_pages/home_page.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneService = PhoneAuthService();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;
  String? _error;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final number = _phoneController.text.trim();
    // Auto-prepend +263 if user enters local format
    if (number.startsWith('0')) {
      return '+263${number.substring(1)}';
    }
    if (!number.startsWith('+')) {
      return '+263$number';
    }
    return number;
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _phoneService.sendOTP(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
          _resendSeconds = 60;
        });
        _startResendTimer();
      },
      onError: (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
      onAutoVerified: (credential) async {
        await _signInWithCredential(credential);
      },
    );
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length < 6) {
      setState(() => _error = 'Please enter the 6-digit OTP');
      return;
    }
    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = await _phoneService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      // Save profile if new user
      await _phoneService.savePhoneUserLocally(
        uid: credential.user!.uid,
        phoneNumber: _fullPhoneNumber,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'invalid-verification-code'
            ? 'Invalid OTP code. Please try again.'
            : 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result =
          await _phoneService.signInWithCredential(credential);
      await _phoneService.savePhoneUserLocally(
        uid: result.user!.uid,
        phoneNumber: _fullPhoneNumber,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = 'Auto-verification failed. Enter OTP manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phone Login',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                _otpSent ? 'Enter OTP' : 'Phone Number',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to $_fullPhoneNumber'
                    : 'We\'ll send a verification code to your phone',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // Phone number field
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Country code badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.inputBorder, width: 1.5),
                      ),
                      child: const Text(
                        '🇿🇼 +263',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '771 234 567',
                          hintStyle: const TextStyle(
                              color: AppColors.textLight, fontSize: 14),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _sendOTP,
                ),
              ] else ...[
                // OTP input boxes
                _buildOTPField(),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Verify OTP',
                  isLoading: _isLoading,
                  onPressed: _verifyOTP,
                ),
                const SizedBox(height: 20),

                // Resend
                Center(
                  child: _resendSeconds > 0
                      ? Text(
                          'Resend OTP in ${_resendSeconds}s',
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 14),
                        )
                      : TextButton(
                          onPressed: _sendOTP,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),

                // Change number
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _error = null;
                    }),
                    child: const Text(
                      'Change phone number',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField() {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 16,
        color: AppColors.primary,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '------',
        hintStyle: TextStyle(
          fontSize: 28,
          letterSpacing: 16,
          color: AppColors.textLight.withOpacity(0.4),
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}