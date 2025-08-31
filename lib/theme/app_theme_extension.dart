import 'package:flutter/material.dart';

@immutable
class AppStyles extends ThemeExtension<AppStyles> {
  final ButtonStyle primaryButton;
  final SnackBarThemeData snackBarTheme;

  const AppStyles({
    required this.primaryButton,
    required this.snackBarTheme,
  });

  @override
  AppStyles copyWith({
    ButtonStyle? primaryButton,
    SnackBarThemeData? snackBarTheme,
  }) => AppStyles(
        primaryButton: primaryButton ?? this.primaryButton,
        snackBarTheme: snackBarTheme ?? this.snackBarTheme,
      );

  @override
  AppStyles lerp(ThemeExtension<AppStyles>? other, double t) {
    if (other is! AppStyles) return this;
    return AppStyles(
      primaryButton: ButtonStyle.lerp(primaryButton, other.primaryButton, t)!,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.lerp(
          snackBarTheme.backgroundColor,
          other.snackBarTheme.backgroundColor,
          t,
        ),
        contentTextStyle: TextStyle.lerp(
          snackBarTheme.contentTextStyle,
          other.snackBarTheme.contentTextStyle,
          t,
        ),
        actionTextColor: Color.lerp(
          snackBarTheme.actionTextColor,
          other.snackBarTheme.actionTextColor,
          t,
        ),
      ),
    );
  }

  static AppStyles create(ColorScheme scheme) => AppStyles(
        primaryButton: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: scheme.primary,
          contentTextStyle: TextStyle(color: scheme.onPrimary),
          actionTextColor: scheme.secondary,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
        ),
      );
}
