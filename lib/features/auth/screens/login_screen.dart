// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/language_provider.dart';
import '../controllers/auth_state.dart';
import '../../../shared/widgets/modern_text_field.dart';
import '../../../shared/widgets/modern_button.dart';
import '../../../shared/utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthState>();

    final success = await authState.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to the main home dashboard route on successful login
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      UIUtils.showSnackBar(context, authState.errorMessage, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      // --- APPBAR WITH LANGUAGE TOGGLE ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              final isAmharic = languageProvider.locale.languageCode == 'am';
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: Text(
                    isAmharic ? 'English' : 'አማርኛ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final newLocale = isAmharic
                        ? const Locale('en')
                        : const Locale('am');
                    languageProvider.setLocale(newLocale);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          // ConstrainedBox limits the form's maximum width on PC/Tablet
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ModernTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Email is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ModernTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password is required'
                          : null,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    ModernButton(
                      onPressed: _handleLogin,
                      text: 'Sign In',
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    // Link to switch to the Register Screen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
