import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TakoPOS color palette - high contrast for POS environments
class AppColors {
  // Primary colors
  static const primary = Color(0xFF1E88E5); // Blue
  static const primaryDark = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF64B5F6);

  // Secondary/Accent
  static const secondary = Color(0xFF26A69A); // Teal
  static const secondaryDark = Color(0xFF00897B);

  // Status colors
  static const success = Color(0xFF43A047);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFFFA000);
  static const warningLight = Color(0xFFFFF8E1);
  static const error = Color(0xFFE53935);
  static const errorLight = Color(0xFFFFEBEE);

  // Background colors
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFEEEEEE);

  // Text colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textOnPrimary = Colors.white;
  static const textOnDark = Colors.white;

  // Cart colors
  static const cartBackground = Color(0xFFFAFAFA);
  static const cartItemBackground = Colors.white;

  // Category chip colors (for visual distinction)
  static const categoryColors = [
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFFCE4EC), // Light Pink
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFE8F5E9), // Light Green
    Color(0xFFFFF8E1), // Light Amber
    Color(0xFFE0F2F1), // Light Teal
    Color(0xFFFBE9E7), // Light Deep Orange
    Color(0xFFEDE7F6), // Light Deep Purple
  ];

  // Dividers and borders
  static const divider = Color(0xFFE0E0E0);
  static const border = Color(0xFFBDBDBD);

  // Shadows
  static const shadow = Color(0x1A000000);
}

/// TakoPOS text styles optimized for readability in fast-paced environments
class AppTextStyles {
  // Headlines
  static TextStyle headline1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle headline2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle headline3 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body text
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Product and price display
  static TextStyle productName = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle productPrice = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static TextStyle cartItemName = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle cartTotal = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Button text
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  // Numeric keypad
  static TextStyle keypadNumber = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle keypadDisplay = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}

/// Spacing constants for consistent layout
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Specific spacing
  static const double cardPadding = 16;
  static const double screenPadding = 16;
  static const double gridSpacing = 12;
}

/// Sizing constants (minimum touch targets for POS)
class AppSizing {
  // Minimum touch target size (48dp recommended by Material Design)
  static const double minTouchTarget = 48;

  // Product grid item sizes
  static const double productTileMinWidth = 120;
  static const double productTileHeight = 140;

  // Button sizes
  static const double buttonHeightSmall = 40;
  static const double buttonHeightMedium = 48;
  static const double buttonHeightLarge = 56;

  // Category tab height
  static const double categoryTabHeight = 48;

  // Cart panel width on tablet (40% of screen)
  static const double cartPanelWidthRatio = 0.4;

  // Numeric keypad button size
  static const double keypadButtonSize = 80;
}

/// Border radius constants
class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double round = 9999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius =
      BorderRadius.all(Radius.circular(round));
}

/// App theme configuration
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(88, AppSizing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(88, AppSizing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(88, AppSizing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.bodyMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadius,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
        titleTextStyle: AppTextStyles.headline3,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
