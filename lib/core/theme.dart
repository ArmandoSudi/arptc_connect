import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Corporate Blue brand palette shared by the application and its modules.
abstract final class CorporateBluePalette {
  static const primary = Color(0xFF155EEF);
  static const primaryDark = Color(0xFF0B4BD4);
  static const primarySoft = Color(0xFFDDE7FF);
  static const secondary = Color(0xFF00A6A6);
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const error = Color(0xFFD92D20);
  static const info = Color(0xFF1570EF);

  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF475467);
  static const border = Color(0xFFD0D5DD);
  static const page = Color(0xFFF6F8FC);
  static const surface = Color(0xFFFFFFFF);

  static const darkPage = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF182230);
  static const darkSurfaceHigh = Color(0xFF202C3D);
  static const darkBorder = Color(0xFF344054);
  static const darkText = Color(0xFFF2F4F7);
  static const darkTextSecondary = Color(0xFFB9C2D0);

  static const tasks = Color(0xFF7C3AED);
  static const inventory = Color(0xFF059669);
  static const incidents = Color(0xFF155EEF);
  static const userManagement = Color(0xFF2563EB);
  static const news = Color(0xFFF59E0B);
  static const courrier = Color(0xFF0891B2);
  static const social = Color(0xFFDB2777);
  static const meeting = Color(0xFF0D9488);
}

/// Semantic design tokens for custom ERP components and future modules.
@immutable
class CorporateThemeTokens extends ThemeExtension<CorporateThemeTokens> {
  const CorporateThemeTokens({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.cardBorder,
    required this.cardShadow,
    required this.chartPalette,
    required this.tasks,
    required this.inventory,
    required this.incidents,
    required this.userManagement,
    required this.news,
    required this.courrier,
    required this.social,
    required this.meeting,
    this.controlRadius = 12,
    this.cardRadius = 16,
    this.panelRadius = 20,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color cardBorder;
  final Color cardShadow;
  final List<Color> chartPalette;
  final Color tasks;
  final Color inventory;
  final Color incidents;
  final Color userManagement;
  final Color news;
  final Color courrier;
  final Color social;
  final Color meeting;
  final double controlRadius;
  final double cardRadius;
  final double panelRadius;

  static const light = CorporateThemeTokens(
    success: CorporateBluePalette.success,
    onSuccess: Colors.white,
    successContainer: Color(0xFFD1FADF),
    onSuccessContainer: Color(0xFF05603A),
    warning: CorporateBluePalette.warning,
    onWarning: Color(0xFF3B2400),
    warningContainer: Color(0xFFFEF0C7),
    onWarningContainer: Color(0xFF7A2E0E),
    info: CorporateBluePalette.info,
    onInfo: Colors.white,
    infoContainer: Color(0xFFD1E9FF),
    onInfoContainer: Color(0xFF1849A9),
    cardBorder: Color(0xFFD8E1EE),
    cardShadow: Color(0x140F2A4F),
    chartPalette: <Color>[
      CorporateBluePalette.primary,
      CorporateBluePalette.secondary,
      CorporateBluePalette.warning,
      CorporateBluePalette.error,
      CorporateBluePalette.success,
      Color(0xFF6172F3),
      Color(0xFF0E9384),
      Color(0xFF667085),
    ],
    tasks: CorporateBluePalette.tasks,
    inventory: CorporateBluePalette.inventory,
    incidents: CorporateBluePalette.incidents,
    userManagement: CorporateBluePalette.userManagement,
    news: CorporateBluePalette.news,
    courrier: CorporateBluePalette.courrier,
    social: CorporateBluePalette.social,
    meeting: CorporateBluePalette.meeting,
  );

  static const dark = CorporateThemeTokens(
    success: Color(0xFF32D583),
    onSuccess: Color(0xFF032B1D),
    successContainer: Color(0xFF074D35),
    onSuccessContainer: Color(0xFFA6F4C5),
    warning: Color(0xFFFDB022),
    onWarning: Color(0xFF3B2400),
    warningContainer: Color(0xFF5F3A05),
    onWarningContainer: Color(0xFFFEF0C7),
    info: Color(0xFF84ADFF),
    onInfo: Color(0xFF102A56),
    infoContainer: Color(0xFF163C78),
    onInfoContainer: Color(0xFFDDE7FF),
    cardBorder: CorporateBluePalette.darkBorder,
    cardShadow: Color(0x66000000),
    chartPalette: <Color>[
      Color(0xFF84ADFF),
      Color(0xFF2ED3B7),
      Color(0xFFFDB022),
      Color(0xFFF97066),
      Color(0xFF32D583),
      Color(0xFF9B8AFB),
      Color(0xFF15B79E),
      Color(0xFF98A2B3),
    ],
    tasks: Color(0xFFA48AFB),
    inventory: Color(0xFF32D583),
    incidents: Color(0xFF84ADFF),
    userManagement: Color(0xFF75A5FF),
    news: Color(0xFFFDB022),
    courrier: Color(0xFF22CCEE),
    social: Color(0xFFEE70A9),
    meeting: Color(0xFF2ED3B7),
  );

  @override
  CorporateThemeTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? cardBorder,
    Color? cardShadow,
    List<Color>? chartPalette,
    Color? tasks,
    Color? inventory,
    Color? incidents,
    Color? userManagement,
    Color? news,
    Color? courrier,
    Color? social,
    Color? meeting,
    double? controlRadius,
    double? cardRadius,
    double? panelRadius,
  }) {
    return CorporateThemeTokens(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      chartPalette: chartPalette ?? this.chartPalette,
      tasks: tasks ?? this.tasks,
      inventory: inventory ?? this.inventory,
      incidents: incidents ?? this.incidents,
      userManagement: userManagement ?? this.userManagement,
      news: news ?? this.news,
      courrier: courrier ?? this.courrier,
      social: social ?? this.social,
      meeting: meeting ?? this.meeting,
      controlRadius: controlRadius ?? this.controlRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      panelRadius: panelRadius ?? this.panelRadius,
    );
  }

  @override
  CorporateThemeTokens lerp(
    covariant CorporateThemeTokens? other,
    double t,
  ) {
    if (other == null) return this;
    return CorporateThemeTokens(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      chartPalette: List<Color>.generate(
        chartPalette.length,
        (index) => Color.lerp(
          chartPalette[index],
          other.chartPalette[index % other.chartPalette.length],
          t,
        )!,
      ),
      tasks: Color.lerp(tasks, other.tasks, t)!,
      inventory: Color.lerp(inventory, other.inventory, t)!,
      incidents: Color.lerp(incidents, other.incidents, t)!,
      userManagement: Color.lerp(userManagement, other.userManagement, t)!,
      news: Color.lerp(news, other.news, t)!,
      courrier: Color.lerp(courrier, other.courrier, t)!,
      social: Color.lerp(social, other.social, t)!,
      meeting: Color.lerp(meeting, other.meeting, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
    );
  }
}

extension CorporateThemeContext on BuildContext {
  CorporateThemeTokens get corporateTheme =>
      Theme.of(this).extension<CorporateThemeTokens>() ??
      CorporateThemeTokens.light;
}

abstract final class CorporateBlueTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: CorporateBluePalette.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: CorporateBluePalette.primary,
          onPrimary: Colors.white,
          primaryContainer: CorporateBluePalette.primarySoft,
          onPrimaryContainer: const Color(0xFF102A56),
          secondary: CorporateBluePalette.secondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFCCFBEF),
          onSecondaryContainer: const Color(0xFF134E48),
          tertiary: CorporateBluePalette.warning,
          onTertiary: const Color(0xFF3B2400),
          tertiaryContainer: const Color(0xFFFEF0C7),
          onTertiaryContainer: const Color(0xFF7A2E0E),
          error: CorporateBluePalette.error,
          onError: Colors.white,
          errorContainer: const Color(0xFFFEE4E2),
          onErrorContainer: const Color(0xFF912018),
          surface: CorporateBluePalette.surface,
          onSurface: CorporateBluePalette.textPrimary,
          onSurfaceVariant: CorporateBluePalette.textSecondary,
          outline: const Color(0xFF98A2B3),
          outlineVariant: CorporateBluePalette.border,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: CorporateBluePalette.page,
          surfaceContainer: const Color(0xFFF2F4F7),
          surfaceContainerHigh: const Color(0xFFEAECF0),
          surfaceContainerHighest: const Color(0xFFE4E7EC),
          inverseSurface: CorporateBluePalette.textPrimary,
          onInverseSurface: Colors.white,
        ),
        tokens: CorporateThemeTokens.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: CorporateBluePalette.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF84ADFF),
          onPrimary: const Color(0xFF102A56),
          primaryContainer: const Color(0xFF163C78),
          onPrimaryContainer: const Color(0xFFDDE7FF),
          secondary: const Color(0xFF2ED3B7),
          onSecondary: const Color(0xFF073A35),
          secondaryContainer: const Color(0xFF125D56),
          onSecondaryContainer: const Color(0xFFCCFBEF),
          tertiary: const Color(0xFFFDB022),
          onTertiary: const Color(0xFF3B2400),
          tertiaryContainer: const Color(0xFF5F3A05),
          onTertiaryContainer: const Color(0xFFFEF0C7),
          error: const Color(0xFFF97066),
          onError: const Color(0xFF55160C),
          errorContainer: const Color(0xFF7A271A),
          onErrorContainer: const Color(0xFFFEE4E2),
          surface: CorporateBluePalette.darkSurface,
          onSurface: CorporateBluePalette.darkText,
          onSurfaceVariant: CorporateBluePalette.darkTextSecondary,
          outline: const Color(0xFF667085),
          outlineVariant: CorporateBluePalette.darkBorder,
          surfaceContainerLowest: CorporateBluePalette.darkPage,
          surfaceContainerLow: const Color(0xFF101828),
          surfaceContainer: CorporateBluePalette.darkSurface,
          surfaceContainerHigh: CorporateBluePalette.darkSurfaceHigh,
          surfaceContainerHighest: const Color(0xFF29384D),
          inverseSurface: CorporateBluePalette.darkText,
          onInverseSurface: CorporateBluePalette.darkPage,
        ),
        tokens: CorporateThemeTokens.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required CorporateThemeTokens tokens,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = base.textTheme
        .apply(
          fontFamily: 'Avenir Next',
          fontFamilyFallback: const <String>['Segoe UI', 'Roboto'],
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.controlRadius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      side: BorderSide(color: tokens.cardBorder),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      canvasColor: scheme.surfaceContainerLow,
      shadowColor: tokens.cardShadow,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: tokens.cardBorder)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.cardShadow,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        useIndicator: true,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 25),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 23,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withOpacity(0.08),
          disabledForegroundColor: scheme.onSurface.withOpacity(0.38),
          elevation: 0,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 1,
          shadowColor: tokens.cardShadow,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withOpacity(0.55)),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.controlRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.32)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.32)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withOpacity(0.75),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.controlRadius),
            borderSide: BorderSide(color: scheme.primary.withOpacity(0.32)),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(controlShape),
          elevation: const WidgetStatePropertyAll(4),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: controlShape,
        textStyle: textTheme.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(controlShape),
          elevation: const WidgetStatePropertyAll(4),
        ),
      ),
      dialogTheme: DialogTheme(
        elevation: 8,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.panelRadius),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outline,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerLow,
        labelStyle:
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        side: BorderSide(color: tokens.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: tokens.cardBorder,
      ),
      dividerTheme: DividerThemeData(
        color: tokens.cardBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: controlShape,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        dataRowColor: WidgetStatePropertyAll(scheme.surface),
        headingTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        dividerThickness: 1,
        decoration: BoxDecoration(
          border: Border.all(color: tokens.cardBorder),
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: controlShape,
        elevation: 6,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: scheme.onError,
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.primary.withOpacity(0.42)),
        trackColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(6),
      ),
    );
  }
}
