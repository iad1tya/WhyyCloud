import 'package:flutter/material.dart';

extension ThemeExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get bgSidebar =>
      isDark ? AppColors.darkBgSidebar : AppColors.lightBgSidebar;
  Color get bgPanel => Theme.of(this).colorScheme.surface;
  Color get bgInput => isDark ? AppColors.darkBgInput : AppColors.lightBgInput;
  Color get bgMsgAi => isDark ? AppColors.darkBgMsgAi : AppColors.lightBgMsgAi;
  Color get bgHover => isDark ? AppColors.darkBgHover : AppColors.lightBgHover;
  Color get border => Theme.of(this).dividerColor;
  Color get borderFaint =>
      isDark ? AppColors.darkBorderFaint : AppColors.lightBorderFaint;

  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textM => isDark ? AppColors.darkTextM : AppColors.lightTextM;
  Color get textD => isDark ? AppColors.darkTextD : AppColors.lightTextD;
}

class AppColors {
  AppColors._();

  static const accent = Color(0xFF60A5FA);
  static const accentDim = Color(0xFF3B82F6);
  static const accentHi = Color(0xFF93C5FD);

  static const accentLight = Color(0xFF000000);
  static const accentDark = Color(0xFFFFFFFF);
  static const green = Color(0xFF3FB950);
  static const red = Color(0xFFF85149);
  static const orange = Color(0xFFE3B341);

  static const darkBg = Color(0xFF000000);
  static const darkBgSidebar = Color(0xFF000000);
  static const darkBgPanel = Color(0xFF0A0A0A);
  static const darkBgInput = Color(0xFF111111);
  static const darkBgMsgAi = Color(0xFF0A0A0A);
  static const darkBgHover = Color(0xFF111111);
  static const darkBorder = Color(0xFF30363D);
  static const darkBorderFaint = Color(0xFF21262D);
  static const darkText = Color(0xFFFFFFFF);
  static const darkTextM = Color(0xFFF2F2F2);
  static const darkTextD = Color(0xFFB3B3B3);

  static const lightBg = Color(0xFFFFFFFF);

  static const lightBgSidebar = Color(0xFFFFFFFF);
  static const lightBgPanel = Color(0xFFFFFFFF);
  static const lightBgInput = Color(0xFFF8FBFF);
  static const lightBgMsgAi = Color(0xFFF8FBFF);
  static const lightBgHover = Color(0xFFEFF8FF);
  static const lightBorder = Color(0xFFCBD5E1);
  static const lightBorderFaint = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightTextM = Color(0xFF475569);
  static const lightTextD = Color(0xFF94A3B8);

  static const uncensored = Color(0xFFEF4444);
  static const standard = Color(0xFF06B6D4);
  static const custom = Color(0xFF22C55E);

  static const accentGradient = LinearGradient(
    colors: [accent, accentHi],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

extension AppThemeColors on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
}
