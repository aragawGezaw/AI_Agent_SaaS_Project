// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/language_provider.dart';
import '../controllers/auth_state.dart';
import '../../../shared/widgets/modern_text_field.dart';
import '../../../shared/widgets/modern_button.dart';
import '../../../shared/utils/ui_utils.dart';
import '../widgets/language_selector.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedLanguage = 'am'; // Default to Amharic for profile preference

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthState>();

    final success = await authState.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      preferredLanguage: _selectedLanguage,
    );

    if (!mounted) return;

    if (success) {
      UIUtils.showSnackBar(context, 'Registration successful! Please sign in.');
      Navigator.pop(context); // Return to Login screen
    } else {
      UIUtils.showSnackBar(context, authState.errorMessage, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      // --- APPBAR WITH GLOBAL LANGUAGE TOGGLE ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
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
                    setState(() {
                      _selectedLanguage = newLocale.languageCode;
                    });
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ModernTextField(
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ModernTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Email is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ModernTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
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
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 16),
                    LanguageSelector(
                      value: _selectedLanguage,
                      onChanged: (val) =>
                          setState(() => _selectedLanguage = val),
                      isAmharic: _selectedLanguage == 'am',
                    ),
                    const SizedBox(height: 24),
                    ModernButton(
                      onPressed: _handleRegister,
                      text: "Register",
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    // --- SIGN IN LINK AT THE BOTTOM ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
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
