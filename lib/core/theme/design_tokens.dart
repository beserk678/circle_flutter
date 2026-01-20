import 'package:flutter/material.dart';

/// Design tokens for consistent UI across the app
class DesignTokens {
  // Base Colors (theme-independent)
  static const primaryColor = Color(0xFF8B5CF6); // Purple
  static const secondaryColor = Color(0xFF6366F1); // Indigo
  static const successColor = Color(0xFF16A34A);
  static const errorColor = Color(0xFFDC2626);
  static const warningColor = Color(0xFFF59E0B);

  // Light Theme Colors
  static const lightBackgroundColor = Colors.white;
  static const lightSurfaceColor = Color(0xFFF8F9FA);
  static const lightCardColor = Colors.white;
  static const lightTextPrimary = Color(0xFF1F2937);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);
  static const lightBorderColor = Color(0xFFE5E7EB);
  static const lightInputFillColor = Color(0xFFF9FAFB);

  // Dark Theme Colors
  static const darkBackgroundColor = Color(0xFF0F0F1E);
  static const darkSurfaceColor = Color(0xFF1A1A2E);
  static const darkCardColor = Color(0xFF252541);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFFD1D5DB);
  static const darkTextTertiary = Color(0xFF9CA3AF);
  static const darkBorderColor = Color(0xFF374151);
  static const darkInputFillColor = Color(0xFF1F2937);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic colors based on theme
  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackgroundColor
          : lightBackgroundColor;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceColor
          : lightSurfaceColor;

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCardColor
          : lightCardColor;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextTertiary
          : lightTextTertiary;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorderColor
          : lightBorderColor;

  static Color inputFillColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkInputFillColor
          : lightInputFillColor;

  // Spacing
  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacing48 = 48.0;

  // Border Radius
  static const radius8 = 8.0;
  static const radius12 = 12.0;
  static const radius16 = 16.0;
  static const radius20 = 20.0;
  static const radius24 = 24.0;
  static const radius32 = 32.0;

  // Shadows
  static List<BoxShadow> cardShadow(BuildContext context) => [
    BoxShadow(
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Common Decorations
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: cardColor(context),
    borderRadius: BorderRadius.circular(radius16),
    boxShadow: cardShadow(context),
  );

  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radius12),
    boxShadow: buttonShadow,
  );

  static InputDecoration inputDecoration(BuildContext context, String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textTertiary(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: BorderSide(color: borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: inputFillColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      );

  // Common Widgets
  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: gradientButtonDecoration,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : icon != null
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: spacing8),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  static Widget outlinedButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(radius12),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius12),
          ),
        ),
        child:
            icon != null
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: primaryColor),
                    const SizedBox(width: spacing8),
                    Text(
                      text,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Text(
                  text,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  static AppBar appBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      backgroundColor: backgroundColor(context),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary(context),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      iconTheme: IconThemeData(color: textPrimary(context)),
    );
  }

  static Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(radius24),
              ),
              child: Icon(icon, size: 50, color: Colors.white),
            ),
            const SizedBox(height: spacing24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacing8),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: textSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
