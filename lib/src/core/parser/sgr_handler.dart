import 'package:flutter/material.dart';
import '../buffer/terminal_cell.dart';
import '../../utils/ansi_colors.dart';

/// Handler for SGR (Select Graphic Rendition) sequences.
///
/// SGR sequences control text style and colors:
/// - ESC[0m: Reset all attributes
/// - ESC[1m: Bold
/// - ESC[3m: Italic
/// - ESC[4m: Underline
/// - ESC[30-37m: Foreground colors (8 basic colors)
/// - ESC[40-47m: Background colors (8 basic colors)
/// - ESC[90-97m: Bright foreground colors
/// - ESC[100-107m: Bright background colors
/// - ESC[38;5;nm: 256-color foreground
/// - ESC[38;2;r;g;bm: RGB foreground
/// - ESC[48;5;nm: 256-color background
/// - ESC[48;2;r;g;bm: RGB background
class SgrHandler {
  /// Apply SGR parameters to a terminal cell style.
  ///
  /// Takes the current style and a list of SGR parameters,
  /// and returns the new style after applying all parameters.
  ///
  /// If [params] is empty, defaults to [0] (reset).
  static TerminalCell applyParams(
    TerminalCell currentStyle,
    List<int> params,
  ) {
    if (params.isEmpty) {
      params = [0]; // Default: reset
    }

    var style = currentStyle;

    for (int i = 0; i < params.length; i++) {
      final param = params[i];

      switch (param) {
        // === Reset and Attributes ===

        case 0: // Reset all attributes
          style = TerminalCell.empty();
          break;

        case 1: // Bold
          style = style.copyWith(isBold: true);
          break;

        case 3: // Italic
          style = style.copyWith(isItalic: true);
          break;

        case 4: // Underline
          style = style.copyWith(isUnderline: true);
          break;

        case 22: // Bold off
          style = style.copyWith(isBold: false);
          break;

        case 23: // Italic off
          style = style.copyWith(isItalic: false);
          break;

        case 24: // Underline off
          style = style.copyWith(isUnderline: false);
          break;

        // === Foreground Colors (30-37) ===

        case >= 30 && <= 37:
          final color = AnsiColors.getForegroundColor(param);
          style = style.copyWith(foregroundColor: color);
          break;

        case 39: // Default foreground color
          style = style.copyWith(foregroundColor: null);
          break;

        // === Background Colors (40-47) ===

        case >= 40 && <= 47:
          final color = AnsiColors.getBackgroundColor(param);
          style = style.copyWith(backgroundColor: color);
          break;

        case 49: // Default background color
          style = style.copyWith(backgroundColor: null);
          break;

        // === Bright Foreground Colors (90-97) ===

        case >= 90 && <= 97:
          final color = AnsiColors.getForegroundColor(param);
          style = style.copyWith(foregroundColor: color);
          break;

        // === Bright Background Colors (100-107) ===

        case >= 100 && <= 107:
          final color = AnsiColors.getBackgroundColor(param);
          style = style.copyWith(backgroundColor: color);
          break;

        // === 256-color and RGB ===

        case 38: // Foreground 256/RGB
          final result = _handle256OrRgbColor(params, i, isForeground: true);
          if (result.color != null) {
            style = style.copyWith(foregroundColor: result.color);
          }
          i = result.newIndex;
          break;

        case 48: // Background 256/RGB
          final result = _handle256OrRgbColor(params, i, isForeground: false);
          if (result.color != null) {
            style = style.copyWith(backgroundColor: result.color);
          }
          i = result.newIndex;
          break;

        // Unknown or unsupported SGR code - ignore
        default:
          break;
      }
    }

    return style;
  }

  /// Handle 256-color or RGB color sequences.
  ///
  /// Formats:
  /// - 256-color: 38;5;n or 48;5;n
  /// - RGB: 38;2;r;g;b or 48;2;r;g;b
  ///
  /// Returns a [_ColorResult] with the parsed color and updated index.
  static _ColorResult _handle256OrRgbColor(
    List<int> params,
    int index, {
    required bool isForeground,
  }) {
    if (index + 1 >= params.length) {
      return _ColorResult(null, index);
    }

    final colorType = params[index + 1];

    if (colorType == 5) {
      // 256-color: 38;5;n or 48;5;n
      if (index + 2 >= params.length) {
        return _ColorResult(null, index);
      }

      final colorIndex = params[index + 2];
      final color = AnsiColors.getColorByIndex(colorIndex);

      return _ColorResult(color, index + 2);
    } else if (colorType == 2) {
      // RGB: 38;2;r;g;b or 48;2;r;g;b
      if (index + 4 >= params.length) {
        return _ColorResult(null, index);
      }

      final r = params[index + 2];
      final g = params[index + 3];
      final b = params[index + 4];
      final color = AnsiColors.fromRgb(r, g, b);

      return _ColorResult(color, index + 4);
    }

    // Unknown format - skip this parameter
    return _ColorResult(null, index + 1);
  }
}

/// Result of parsing a 256-color or RGB sequence.
class _ColorResult {
  /// The parsed color, or null if parsing failed.
  final Color? color;

  /// The new index position after consuming parameters.
  final int newIndex;

  const _ColorResult(this.color, this.newIndex);
}
