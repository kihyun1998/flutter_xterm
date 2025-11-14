import 'package:flutter/material.dart';
import '../core/buffer/cursor.dart';

/// Theme configuration for terminal rendering.
///
/// This class defines all styling properties for terminal rendering including
/// fonts, colors, cursor appearance, and layout.
///
/// Note: This class is not marked as @immutable because it uses internal
/// caching for the cellSize property to improve performance.
class TerminalTheme {
  // === Font Settings ===

  /// Font family to use for terminal text.
  /// Should be a monospace font for proper alignment.
  final String fontFamily;

  /// Font size in logical pixels.
  final double fontSize;

  // === Color Settings ===

  /// Default foreground (text) color when no color is specified.
  final Color defaultForegroundColor;

  /// Default background color for the terminal.
  final Color defaultBackgroundColor;

  // === Cursor Settings ===

  /// Style of the cursor (block, underline, or bar).
  final CursorStyle cursorStyle;

  /// Color of the cursor.
  final Color cursorColor;

  /// Interval between cursor blinks.
  final Duration cursorBlinkInterval;

  // === Layout Settings ===

  /// Line height multiplier for vertical cell spacing.
  /// This is applied to the base cell height to add vertical spacing.
  /// 1.0 = no extra spacing, 1.2 = 20% extra spacing between lines.
  final double lineHeight;

  /// Padding around the terminal content.
  final EdgeInsets padding;

  // === Color Palette ===

  /// Custom 256-color palette. If null, uses AnsiColors.palette256.
  final List<Color>? customPalette;

  /// Cached cell size to avoid recalculation.
  Size? _cachedCellSize;

  /// Creates a terminal theme with the specified properties.
  TerminalTheme({
    this.fontFamily = 'monospace',
    this.fontSize = 14.0,
    this.defaultForegroundColor = Colors.white,
    this.defaultBackgroundColor = Colors.black,
    this.cursorStyle = CursorStyle.block,
    this.cursorColor = Colors.white,
    this.cursorBlinkInterval = const Duration(milliseconds: 530),
    this.lineHeight = 1.2,
    this.padding = const EdgeInsets.all(8.0),
    this.customPalette,
  });

  /// Creates a dark theme (default).
  factory TerminalTheme.dark() {
    return TerminalTheme();
  }

  /// Creates a light theme.
  factory TerminalTheme.light() {
    return TerminalTheme(
      defaultForegroundColor: Colors.black,
      defaultBackgroundColor: Colors.white,
      cursorColor: Colors.black,
    );
  }

  /// Creates a copy of this theme with some properties replaced.
  TerminalTheme copyWith({
    String? fontFamily,
    double? fontSize,
    Color? defaultForegroundColor,
    Color? defaultBackgroundColor,
    CursorStyle? cursorStyle,
    Color? cursorColor,
    Duration? cursorBlinkInterval,
    double? lineHeight,
    EdgeInsets? padding,
    List<Color>? customPalette,
  }) {
    return TerminalTheme(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      defaultForegroundColor:
          defaultForegroundColor ?? this.defaultForegroundColor,
      defaultBackgroundColor:
          defaultBackgroundColor ?? this.defaultBackgroundColor,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorBlinkInterval: cursorBlinkInterval ?? this.cursorBlinkInterval,
      lineHeight: lineHeight ?? this.lineHeight,
      padding: padding ?? this.padding,
      customPalette: customPalette ?? this.customPalette,
    );
  }

  /// Gets the size of a single terminal cell.
  ///
  /// This is calculated by measuring a single 'W' character with the
  /// specified font settings. The result is cached for performance.
  Size get cellSize {
    if (_cachedCellSize != null) {
      return _cachedCellSize!;
    }

    // Measure a sample character to determine cell size
    // Use the same TextStyle as actual rendering for consistency
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'W',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          // Don't specify height - use default for natural rendering
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Cell size is the natural text size (lineHeight is currently not used)
    _cachedCellSize = Size(
      textPainter.width,
      textPainter.height,
    );

    return _cachedCellSize!;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalTheme &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          defaultForegroundColor == other.defaultForegroundColor &&
          defaultBackgroundColor == other.defaultBackgroundColor &&
          cursorStyle == other.cursorStyle &&
          cursorColor == other.cursorColor &&
          cursorBlinkInterval == other.cursorBlinkInterval &&
          lineHeight == other.lineHeight &&
          padding == other.padding &&
          customPalette == other.customPalette;

  @override
  int get hashCode =>
      fontFamily.hashCode ^
      fontSize.hashCode ^
      defaultForegroundColor.hashCode ^
      defaultBackgroundColor.hashCode ^
      cursorStyle.hashCode ^
      cursorColor.hashCode ^
      cursorBlinkInterval.hashCode ^
      lineHeight.hashCode ^
      padding.hashCode ^
      customPalette.hashCode;

  @override
  String toString() {
    return 'TerminalTheme('
        'fontFamily: $fontFamily, '
        'fontSize: $fontSize, '
        'cursorStyle: $cursorStyle, '
        'lineHeight: $lineHeight)';
  }
}
