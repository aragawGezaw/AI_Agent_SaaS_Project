import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_state.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _fullName = '';
  String _preferredLanguage = 'am';
  bool _isRegistering = false;
  bool _isLoggingIn = false;
  String _errorMessage = '';

  void _switchToLogin() {
    setState(() {
      _isRegistering = false;
      _isLoggingIn = false;
      _errorMessage = '';
    });
  }

  void _switchToRegister() {
    setState(() {
      _isRegistering = true;
      _isLoggingIn = false;
      _errorMessage = '';
    });
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }
    _registerFormKey.currentState!.save();

    setState(() {
      _isRegistering = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'password': _password,
          'full_name': _fullName,
          'preferred_language': _preferredLanguage,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(response.body)['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }
    _loginFormKey.currentState!.save();

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'password': _password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['access_token'];
        if (token != null) {
          await SecureStorageService().saveToken(token);
        }

        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(response.body)['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthState>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isAmharic = languageProvider.locale.languageCode == 'am';
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegistering
              ? (localizations?.registerTitle ?? 'Register')
              : (localizations?.loginTitle ?? 'Login'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: languageProvider.locale.languageCode,
              icon: const Icon(Icons.language, color: Colors.green),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.changeLanguage(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'am',
                  child: Text('አማርኛ'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _isRegistering ? _registerFormKey : _loginFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRegistering) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations?.emailLabel ?? 'Email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic ? 'ኢሜይል ያስፈልጋል' : 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return isAmharic
                            ? 'ልክ ያልሆነ የኢሜይል ቅርጸት'
                            : 'Invalid email format';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: localizations?.passwordLabel ?? 'Password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic
                            ? 'የይለፍ ቃል ያስፈልጋል'
                            : 'Password is required';
                      }
                      if (value.length < 6) {
                        return isAmharic
                            ? 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት'
                            : 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: isAmharic ? 'ሙሉ ስም' : 'Full Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic
                            ? 'ሙሉ ስም ያስፈልጋል'
                            : 'Full name is required';
                      }
                      return null;
                    },
                    onSaved: (value) => _fullName = value ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey(languageProvider.locale.languageCode),
                    initialValue: languageProvider.locale.languageCode,
                    decoration: InputDecoration(
                      labelText: isAmharic ? 'የተመረጠ ቋንቋ' : 'Preferred Language',
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic ? 'ቋንቋ ያስፈልጋል' : 'Language is required';
                      }
                      return null;
                    },
                    onSaved: (value) => _preferredLanguage = value ?? 'am',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isRegistering ? _submitRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      localizations?.registerButton ?? 'Register',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations?.emailLabel ?? 'Email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic ? 'ኢሜይል ያስፈልጋል' : 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return isAmharic
                            ? 'ልክ ያልሆነ የኢሜይል ቅርጸት'
                            : 'Invalid email format';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: localizations?.passwordLabel ?? 'Password',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return isAmharic
                            ? 'የይለፍ ቃል ያስፈልጋል'
                            : 'Password is required';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value ?? '',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      localizations?.loginButton ?? 'Login',
                    ),
                  ),
                ],
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextButton(
          onPressed: _isRegistering ? _switchToLogin : _switchToRegister,
          child: Text(
            _isRegistering
                ? (isAmharic
                    ? 'አካውንት አለዎት? ይግቡ'
                    : 'Already have an account? Login')
                : (isAmharic
                    ? 'አካውንት የለዎትም? ይመዝገቡ'
                    : 'Don\'t have an account? Register'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isRegistering) {
            _switchToLogin();
          } else {
            _switchToRegister();
          }
        },
        backgroundColor: Colors.grey,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
