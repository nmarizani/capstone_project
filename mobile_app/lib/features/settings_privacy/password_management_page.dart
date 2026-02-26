import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  String? _success;

  final _authService = AuthService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      // Get current user's ID number (email prefix)
      final email = _authService.currentUser?.email ?? '';
      final idNumber = email.split('@').first;

      await _authService.reauthenticate(
        idNumber: idNumber,
        currentPassword: _currentPasswordController.text,
      );
      await _authService.updatePassword(_newPasswordController.text);

      setState(() => _success = 'Password changed successfully!');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() => _error = 'Failed to change password. Check your current password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text(
          'Password Manager',
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
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Current Password'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _currentPasswordController,
                  hintText: '••••••••••••',
                  obscureText: _obscureCurrent,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              color: AppColors.primary, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ],
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter current password' : null,
                ),
                const SizedBox(height: 20),

                const _FieldLabel('New Password'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _newPasswordController,
                  hintText: '••••••••••••',
                  obscureText: _obscureNew,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter new password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const _FieldLabel('Confirm New Password'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: '••••••••••••',
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                ],

                if (_success != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_success!,
                        style: const TextStyle(color: AppColors.success)),
                  ),
                ],

                const SizedBox(height: 32),
                GradientButton(
                  text: 'Change Password',
                  isLoading: _isLoading,
                  onPressed: _changePassword,
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