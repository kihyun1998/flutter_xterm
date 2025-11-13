import 'package:flutter/material.dart';

/// ANSI standard color palette for terminal emulation.
///
/// Provides colors for:
/// - Basic 16 colors (SGR 30-37, 40-47, 90-97, 100-107)
/// - 256-color palette (SGR 38;5;n, 48;5;n)
/// - RGB true color (SGR 38;2;r;g;b, 48;2;r;g;b)
class AnsiColors {
  // === Basic 8 Colors (30-37, 40-47) ===

  static const Color black = Color(0xFF000000);
  static const Color red = Color(0xFFCD0000);
  static const Color green = Color(0xFF00CD00);
  static const Color yellow = Color(0xFFCDCD00);
  static const Color blue = Color(0xFF0000EE);
  static const Color magenta = Color(0xFFCD00CD);
  static const Color cyan = Color(0xFF00CDCD);
  static const Color white = Color(0xFFE5E5E5);

  // === Bright 8 Colors (90-97, 100-107) ===

  static const Color brightBlack = Color(0xFF7F7F7F);
  static const Color brightRed = Color(0xFFFF0000);
  static const Color brightGreen = Color(0xFF00FF00);
  static const Color brightYellow = Color(0xFFFFFF00);
  static const Color brightBlue = Color(0xFF5C5CFF);
  static const Color brightMagenta = Color(0xFFFF00FF);
  static const Color brightCyan = Color(0xFF00FFFF);
  static const Color brightWhite = Color(0xFFFFFFFF);

  /// Basic 16-color palette.
  static const List<Color> palette16 = [
    // 0-7: Normal colors
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    // 8-15: Bright colors
    brightBlack,
    brightRed,
    brightGreen,
    brightYellow,
    brightBlue,
    brightMagenta,
    brightCyan,
    brightWhite,
  ];

  /// 256-color palette.
  ///
  /// Color indices:
  /// - 0-15: Basic 16 colors
  /// - 16-231: 6x6x6 RGB cube (216 colors)
  /// - 232-255: Grayscale (24 shades)
  static List<Color> get palette256 {
    final colors = <Color>[];

    // 0-15: Basic 16 colors
    colors.addAll(palette16);

    // 16-231: 6x6x6 RGB cube
    for (int r = 0; r < 6; r++) {
      for (int g = 0; g < 6; g++) {
        for (int b = 0; b < 6; b++) {
          final red = r == 0 ? 0 : 55 + r * 40;
          final green = g == 0 ? 0 : 55 + g * 40;
          final blue = b == 0 ? 0 : 55 + b * 40;
          colors.add(Color.fromARGB(255, red, green, blue));
        }
      }
    }

    // 232-255: Grayscale
    for (int i = 0; i < 24; i++) {
      final gray = 8 + i * 10;
      colors.add(Color.fromARGB(255, gray, gray, gray));
    }

    return colors;
  }

  /// Cached 256-color palette for performance.
  static final List<Color> _cachedPalette256 = palette256;

  /// Get color by ANSI 256-color index (0-255).
  ///
  /// Returns null if the index is out of range.
  static Color? getColorByIndex(int index) {
    if (index >= 0 && index < 256) {
      return _cachedPalette256[index];
    }
    return null;
  }

  /// Create a color from RGB values (0-255).
  static Color fromRgb(int r, int g, int b) {
    return Color.fromARGB(
      255,
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
    );
  }

  /// Get foreground color by SGR code (30-37, 90-97).
  ///
  /// Returns null if the code is not a valid foreground color code.
  static Color? getForegroundColor(int code) {
    if (code >= 30 && code <= 37) {
      return palette16[code - 30];
    } else if (code >= 90 && code <= 97) {
      return palette16[code - 90 + 8];
    }
    return null;
  }

  /// Get background color by SGR code (40-47, 100-107).
  ///
  /// Returns null if the code is not a valid background color code.
  static Color? getBackgroundColor(int code) {
    if (code >= 40 && code <= 47) {
      return palette16[code - 40];
    } else if (code >= 100 && code <= 107) {
      return palette16[code - 100 + 8];
    }
    return null;
  }
}
