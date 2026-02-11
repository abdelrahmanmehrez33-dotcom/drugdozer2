import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = false;
  
  bool get isEnglish => _isEnglish;
  
  void switchToArabic() {
    _isEnglish = false;
    notifyListeners();
  }
  
  void switchToEnglish() {
    _isEnglish = true;
    notifyListeners();
  }
  
  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }
}