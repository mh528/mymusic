import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF000000);
  static const bg1 = Color(0xFF1A1A1A);
  static const bg2 = Color(0xFF222222);
  static const bg3 = Color(0xFF333333);
  static const divider = Color(0xFF404040);
  static const textDim = Color(0xFF666666);
  static const textMuted = Color(0xFF888888);
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFFF3B30);
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.black,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.black,
    onSurface: AppColors.white,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    error: AppColors.red,
    onError: AppColors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.black,
    foregroundColor: AppColors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.black,
    indicatorColor: Colors.transparent,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.white);
      }
      return const IconThemeData(color: AppColors.textMuted);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: AppColors.white, fontSize: 11);
      }
      return const TextStyle(color: AppColors.textMuted, fontSize: 11);
    }),
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bg1,
    modalBackgroundColor: AppColors.bg1,
    showDragHandle: false,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 0,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.black;
      return AppColors.textMuted;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.white;
      return AppColors.bg3;
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.transparent,
    selectedColor: AppColors.white,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    secondaryLabelStyle: const TextStyle(color: AppColors.black, fontSize: 13),
    side: const BorderSide(color: AppColors.divider),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: AppColors.white, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.white, fontSize: 14),
    bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
    labelSmall: TextStyle(color: AppColors.textMuted, fontSize: 10),
  ),
  iconTheme: const IconThemeData(color: AppColors.white),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.white,
    linearTrackColor: AppColors.bg3,
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: AppColors.white,
    inactiveTrackColor: AppColors.bg3,
    thumbColor: AppColors.white,
    overlayColor: Colors.transparent,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColors.bg1,
    titleTextStyle: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
    contentTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bg2,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  useMaterial3: true,
);

/// Semantic text style aliases — use these instead of raw TextStyle in widgets.
/// All values are taken from appTheme.textTheme so they stay in sync.
class AppTextStyles {
  // Page / section titles
  static const pageTitle = TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold);
  static const sectionTitle = TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600);

  // List rows
  static const listTitle = TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.normal);
  static const listSubtitle = TextStyle(color: AppColors.textMuted, fontSize: 12);

  // Body copy
  static const body = TextStyle(color: AppColors.white, fontSize: 14);
  static const bodyMuted = TextStyle(color: AppColors.textMuted, fontSize: 14);
  static const caption = TextStyle(color: AppColors.textMuted, fontSize: 12);

  // Settings rows
  static const settingTitle = TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500);
  static const settingCaption = TextStyle(color: AppColors.textMuted, fontSize: 12);

  // Tabs / chips
  static const tabActive = TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold);
  static const tabInactive = TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.normal);
  static const chipLabel = TextStyle(fontSize: 13);
}
