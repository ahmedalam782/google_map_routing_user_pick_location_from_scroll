import 'package:flutter/material.dart';

class MdUserPickLocationGoogleMapConfig {
  static String _apiKey = '';
  static String _baseUrl = '';
  static String _fontFamily = '';
  static Color? _primaryColor;
  static String _userAgent = 'MdSoftGoogleMapUserPickLocationFromScroll/1.0 (info@mdsoft.com)';

  static void initialize({
    required String apiKey,
    Color? primaryColor,
    String? fontFamily,
    required String baseUrl,
    String? userAgent,
  }) async {
    _apiKey = apiKey;
    _primaryColor = primaryColor ?? const Color(0xffD60020);
    _baseUrl = baseUrl;
    _fontFamily = fontFamily ?? 'Hanimation Arabic';
    if (userAgent != null) {
      _userAgent = userAgent;
    }
  }

  static String get apiKey => _apiKey;
  static String get baseUrl => _baseUrl;
  static String get fontFamily => _fontFamily;
  static Color? get primaryColor => _primaryColor;
  static String get userAgent => _userAgent;
}
