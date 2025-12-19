import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors - Blue Shades
  static const Color primaryBlue = Color.fromARGB(255, 39, 158, 255);
  static const Color primaryBlueDark = Color.fromARGB(255, 69, 49, 247);
  static const Color primaryBlueLight = Color.fromARGB(255, 0, 119, 255);
  static const Color primaryBlueAccent = Color.fromARGB(255, 36, 105, 255);

  // Secondary Blues
  static const Color lightBlue = Color.fromARGB(255, 157, 200, 255);
  static const Color mediumBlue = Color.fromARGB(255, 34, 74, 255);
  static const Color darkBlue = Color(0xFF1E40AF);
  static const Color navyBlue = Color(0xFF1E3A8A);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF2C3E50);
  static const Color mediumGray = Color(0xFF4A5568);
  static const Color lightGray = Color(0xFF718096);
  static const Color paleGray = Color(0xFFF7FAFC);
  static const Color borderGray = Color(0xFFE2E8F0);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardBackgroundColor = white;
  static const Color scaffoldBackgroundColor = backgroundColor;

  // Status Colors
  static const Color successGreen = Color(0xFF28a745);
  static const Color warningOrange = Color(0xFFffc107);
  static const Color errorRed = Color(0xFFdc3545);
  static const Color infoBlue = Color(0xFF007bff);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundColor, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: darkGray,
    letterSpacing: 0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: white,
    letterSpacing: 0.5,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: darkGray,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: darkGray,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: mediumGray,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: lightGray,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: white,
  );

  static const TextStyle priceText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    shadowColor: primaryBlue.withOpacity(0.3),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryBlue,
    side: const BorderSide(color: primaryBlue, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: errorRed,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Input Decoration
  static InputDecoration textFieldDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: primaryBlue) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      filled: true,
      fillColor: white,
      labelStyle: const TextStyle(color: mediumGray),
      hintStyle: const TextStyle(color: lightGray),
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderGray, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade100,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration gradientCardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderGray, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade100,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Status Chip Styles
  static BoxDecoration statusChipDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // App Bar Theme
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: headingMedium,
    iconTheme: IconThemeData(color: white),
  );

  // Bottom Navigation Theme
  static BottomNavigationBarThemeData bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: white,
    selectedItemColor: primaryBlue,
    unselectedItemColor: lightGray,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // Floating Action Button Theme
  static FloatingActionButtonThemeData fabTheme =
      const FloatingActionButtonThemeData(
    backgroundColor: primaryBlue,
    foregroundColor: white,
    elevation: 6,
  );

  // Complete Material Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: primaryBlueAccent,
        surface: white,
        background: backgroundColor,
        error: errorRed,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      floatingActionButtonTheme: fabTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: white,
      ),
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      dividerColor: borderGray,
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 1,
        space: 16,
      ),
    );
  }

  // Helper Methods
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return successGreen;
      case 'shipped':
      case 'in transit':
        return infoBlue;
      case 'processing':
        return warningOrange;
      case 'cancelled':
        return errorRed;
      case 'pending':
      default:
        return mediumGray;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'shipped':
      case 'in transit':
        return Icons.local_shipping;
      case 'processing':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  // Shadow Styles
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get heavyShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
}
