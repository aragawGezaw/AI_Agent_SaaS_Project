import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/storage/secure_storage_service.dart';

/// Smart Nutrition & Health - Authentication Screen (Redesigned Phase 6)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _fullName = '';
  String _preferredLanguage = 'am';
  bool _isRegistering = false;
  bool _isLoggingIn = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchMode() {
    _animController.reset();
    setState(() {
      _isRegistering = !_isRegistering;
      _errorMessage = '';
      _email = '';
      _password = '';
      _fullName = '';
    });
    _animController.forward();
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    _registerFormKey.currentState!.save();
    setState(() => _isRegistering = true);

    try {
      final resp = await http.post(
        Uri.parse('http://localhost:5000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'password': _password,
          'full_name': _fullName,
          'preferred_language': _preferredLanguage,
        }),
      );
      if (resp.statusCode == 201) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = jsonDecode(resp.body)['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    _loginFormKey.currentState!.save();
    setState(() => _isLoggingIn = true);

    try {
      final resp = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'password': _password}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['token'] ?? data['access_token'];
        if (token != null) {
          await SecureStorageService().saveToken(token);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = jsonDecode(resp.body)['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isAm = languageProvider.locale.languageCode == 'am';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF00695C),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language toggle in top-right corner
              Positioned(
                top: 8,
                right: 12,
                child: _LanguageToggleButton(
                  currentLocale: languageProvider.locale,
                  onToggle: (code) => languageProvider.changeLanguage(code),
                ),
              ),
              // Main scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height * 0.85),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BrandingHeader(isAmharic: isAm),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _AuthCard(
                            isRegistering: _isRegistering,
                            isLoggingIn: _isLoggingIn,
                            obscurePassword: _obscurePassword,
                            errorMessage: _errorMessage,
                            loginFormKey: _loginFormKey,
                            registerFormKey: _registerFormKey,
                            isAmharic: isAm,
                            onEmailSaved: (v) => _email = v ?? '',
                            onPasswordSaved: (v) => _password = v ?? '',
                            onFullNameSaved: (v) => _fullName = v ?? '',
                            onLanguageChanged: (v) => _preferredLanguage = v,
                            onTogglePasswordVisibility: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            onSubmitLogin: _submitLogin,
                            onSubmitRegister: _submitRegister,
                            onSwitchMode: _switchMode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  final bool isAmharic;
  const _BrandingHeader({required this.isAmharic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          isAmharic ? 'ስማርት አምጋገብ እና ጤና' : 'Smart Nutrition',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAmharic
              ? 'የግልዎ የተመጣጠነ ምግብ እና የግላይስሚክ መመሪያ'
              : 'Your Personalized Nutrition & Glycemic Guide',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAmharic ? '& Health SaaS' : '& Health',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.60),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isRegistering;
  final bool isLoggingIn;
  final bool obscurePassword;
  final String errorMessage;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final bool isAmharic;
  final ValueChanged<String?> onEmailSaved;
  final ValueChanged<String?> onPasswordSaved;
  final ValueChanged<String?> onFullNameSaved;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmitLogin;
  final VoidCallback onSubmitRegister;
  final VoidCallback onSwitchMode;

  const _AuthCard({
    required this.isRegistering,
    required this.isLoggingIn,
    required this.obscurePassword,
    required this.errorMessage,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.isAmharic,
    required this.onEmailSaved,
    required this.onPasswordSaved,
    required this.onFullNameSaved,
    required this.onLanguageChanged,
    required this.onTogglePasswordVisibility,
    required this.onSubmitLogin,
    required this.onSubmitRegister,
    required this.onSwitchMode,
  });

  bool get _isLoading => isLoggingIn || isRegistering;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.06),
                  const Color(0xFF00695C).withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  isRegistering
                      ? (isAmharic ? 'Create Account' : 'Create Account')
                      : (isAmharic ? 'Sign In' : 'Welcome Back'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRegistering
                      ? (isAmharic
                          ? 'Start your healthy journey today'
                          : 'Start your healthy journey today')
                      : (isAmharic
                          ? 'Sign in to continue your journey'
                          : 'Sign in to continue your journey'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: isRegistering ? _buildRegisterForm() : _buildLoginForm(),
          ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFC62828), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (isRegistering ? onSubmitRegister : onSubmitLogin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF2E7D32).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isRegistering
                            ? (isAmharic ? 'Create Account' : 'Create Account')
                            : (isAmharic ? 'Sign In' : 'Sign In'),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isRegistering
                      ? (isAmharic
                          ? 'Already have an account?'
                          : 'Already have an account?')
                      : (isAmharic
                          ? "Don't have an account?"
                          : "Don't have an account?"),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _isLoading ? null : onSwitchMode,
                  child: Text(
                    isRegistering
                        ? (isAmharic ? 'Sign In' : 'Sign In')
                        : (isAmharic ? 'Create Account' : 'Create Account'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: loginFormKey,
      child: Column(
        children: [
          _ModernTextField(
            label: isAmharic ? 'Email' : 'Email Address',
            hint: isAmharic ? 'you@example.com' : 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _emailValidator,
            onSaved: onEmailSaved,
          ),
          const SizedBox(height: 16),
          _ModernTextField(
            label: isAmharic ? 'Password' : 'Password',
            hint: isAmharic
                ? 'Enter your password'
                : 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
            textInputAction: TextInputAction.done,
            validator: _passwordValidator,
            onSaved: onPasswordSaved,
            onFieldSubmitted: (_) => onSubmitLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: registerFormKey,
      child: Column(
        children: [
          _ModernTextField(
            label: isAmharic ? 'Full Name' : 'Full Name',
            hint: isAmharic ? 'e.g. John Doe' : 'e.g. John Doe',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? (isAmharic ? 'Name is required' : 'Full name is required')
                : null,
            onSaved: onFullNameSaved,
          ),
          const SizedBox(height: 16),
          _ModernTextField(
            label: isAmharic ? 'Email' : 'Email Address',
            hint: isAmharic ? 'you@example.com' : 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _emailValidator,
            onSaved: onEmailSaved,
          ),
          const SizedBox(height: 16),
          _ModernTextField(
            label: isAmharic ? 'Password' : 'Password',
            hint: isAmharic
                ? 'Create a strong password'
                : 'Create a strong password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
            textInputAction: TextInputAction.done,
            validator: _passwordValidator,
            onSaved: onPasswordSaved,
            onFieldSubmitted: (_) => onSubmitRegister(),
          ),
          const SizedBox(height: 20),
          _LanguageSelector(
            value: 'am',
            onChanged: onLanguageChanged,
            isAmharic: isAmharic,
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isAmharic ? 'Email is required' : 'Email is required';
    }
    if (!RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value)) {
      return isAmharic ? 'Invalid email' : 'Invalid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return isAmharic ? 'Password is required' : 'Password is required';
    }
    if (isRegistering && value.length < 6) {
      return isAmharic
          ? 'Password must be 6+ characters'
          : 'Password must be at least 6 characters';
    }
    return null;
  }
}

class _ModernTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String?)? onFieldSubmitted;

  const _ModernTextField({
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onSaved: onSaved,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 14, right: 8),
          child: Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 20),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F8F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.8),
        ),
        errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool isAmharic;

  const _LanguageSelector({
    required this.value,
    required this.onChanged,
    required this.isAmharic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.language_rounded, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'am',
                    child: Row(
                      children: [
                        Text('Amharic', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text('(Amharic)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: [
                        Text('English', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text('(English)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) => onChanged(v ?? value),
              ),
            ),
          ),
        ],
      ),
    );
  }
/// Language toggle button shown in the top-right corner of the auth screen.
}
class _LanguageToggleButton extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<String> onToggle;

  const _LanguageToggleButton({
    required this.currentLocale,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAm = currentLocale.languageCode == 'am';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onToggle(isAm ? 'en' : 'am'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language_rounded,
                  color: Colors.white.withValues(alpha: 0.90),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isAm ? 'EN' : 'አማ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
