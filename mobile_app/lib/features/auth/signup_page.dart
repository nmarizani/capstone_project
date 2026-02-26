import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import 'set_password_page.dart';
import 'login_page.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _stationIdController = TextEditingController();
  bool _obscureStationId = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _stationIdController.dispose();
    super.dispose();
  }

  void _proceedToSetPassword() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(
          fullName: _nameController.text.trim(),
          idNumber: _idController.text.trim(),
          stationIdNumber: _stationIdController.text.trim(),
        ),
      ),
    );
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
          'New Account',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Full Name
                const _FieldLabel('Full name'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'first name last name',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 20),

                // ID Number
                const _FieldLabel('ID Number'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _idController,
                  hintText: '101909102920101',
                  keyboardType: TextInputType.number,
                  suffixIcon: const Icon(Icons.visibility, color: AppColors.textLight, size: 20),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your ID number' : null,
                ),
                const SizedBox(height: 20),

                // Station ID Number
                const _FieldLabel('Station ID Number'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _stationIdController,
                  hintText: '506070',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter Station ID' : null,
                ),

                const SizedBox(height: 12),

                // Terms
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'By continuing, you agree to\n',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Use',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                GradientButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _proceedToSetPassword,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: 'already have an account? ',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}