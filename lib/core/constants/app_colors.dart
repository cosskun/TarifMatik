import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFFFF5722); // Vibrant coral orange
  static const Color primaryDark = Color(0xFFFF7043); // Soft coral orange for dark mode
  static const Color secondary = Color(0xFFFFB300); // Warm amber
  static const Color secondaryDark = Color(0xFFFFCA28); // Golden amber for dark mode
  
  // Neutral Backgrounds
  static const Color scaffoldLight = Color(0xFFFDFBF7); // Cozy off-white cream
  static const Color scaffoldDark = Color(0xFF121212); // Deep charcoal
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF252525);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Category Colors
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Sebze/Meyve':
        return Colors.green;
      case 'Süt Ürünleri':
        return Colors.blue;
      case 'Et & Şarküteri':
        return Colors.red;
      case 'Kuru Gıda':
        return Colors.amber[800]!;
      case 'Tatlı':
        return Colors.purple;
      case 'İçecek':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }
}
