import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _facilityCodeCtrl = TextEditingController(text: 'ZW-HRE-01');

  bool _obscure = true;
  bool _rememberDevice = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _facilityCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // TODO: Replace with real auth API / local auth logic later
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: cs.primary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Sign in with facility-issued credentials. Offline mode and PIN login can be enabled later.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _identifierCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username or Email',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your username or email';
                            }
                            if (v.trim().length < 3) {
                              return 'Too short';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter password';
                            if (v.length < 4) return 'Password too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _facilityCodeCtrl,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Facility Code',
                            prefixIcon: Icon(Icons.local_hospital_outlined),
                            helperText: 'Used to tag records to the correct facility',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter facility code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),

                        CheckboxListTile(
                          value: _rememberDevice,
                          onChanged: (v) =>
                              setState(() => _rememberDevice = v ?? true),
                          title: const Text('Remember this device'),
                          subtitle: const Text(
                            'Allows faster sign-in and offline continuity',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 4),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: const Icon(Icons.login),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Sign In'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot password.'),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                      const Text(' • '),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN login setup.'),
                            ),
                          );
                        },
                        child: const Text('Use PIN'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Privacy reminder'),
                      subtitle: const Text(
                        'Use local patient IDs only. Do not enter names unless required by facility policy.',
                      ),
                    ),
                  ),
                ],
              ),

              if (_isSubmitting)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}