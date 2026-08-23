import 'package:flutter/material.dart';
import '../storage/secure_storage_service.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('am'); // Defaulting to Amharic as per cultural/local context guidelines, or English. Let's load the saved one, defaulting to 'am' or 'en'
  final SecureStorageService _storageService = SecureStorageService();

  LanguageProvider() {
    _loadLanguage();
  }

  Locale get locale => _locale;

  Future<void> _loadLanguage() async {
    try {
      final lang = await _storageService.getLanguage();
      if (lang != null && (lang == 'en' || lang == 'am')) {
        _locale = Locale(lang);
        notifyListeners();
      } else {
        // Fallback to check if a user session preferred language is saved
        final session = await _storageService.getSession();
        if (session != null) {
          final preferredLang = session['preferred_language'] as String?;
          if (preferredLang == 'en' || preferredLang == 'am') {
            final lang = preferredLang!;
            _locale = Locale(lang);
            await _storageService.saveLanguage(lang);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Gracefully fallback on error
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == 'en' || languageCode == 'am') {
      _locale = Locale(languageCode);
      try {
        await _storageService.saveLanguage(languageCode);
      } catch (e) {
        debugPrint('Error saving language: $e');
      }
      notifyListeners();
    }
  }
}