import 'package:flutter/material.dart';
import '../core/buffer/terminal_cell.dart';
import 'terminal_theme.dart';

/// Cache for TextPainter instances to improve rendering performance.
///
/// This class caches TextPainter objects based on the text style (colors,
/// bold, italic, underline) to avoid recreating them for every cell.
class TextStyleCache {
  /// Internal cache mapping style hash to TextPainter.
  final Map<int, TextPainter> _cache = {};

  /// Maximum number of cached TextPainter instances.
  /// This prevents unbounded memory growth.
  static const int maxCacheSize = 256;

  /// Gets a TextPainter for the given cell and theme.
  ///
  /// If a TextPainter with the same style exists in the cache, it is reused.
  /// Otherwise, a new TextPainter is created, cached, and returned.
  TextPainter getPainter(TerminalCell cell, TerminalTheme theme) {
    final hash = _computeStyleHash(cell, theme);

    if (_cache.containsKey(hash)) {
      final painter = _cache[hash]!;
      // Update the text if it's different
      if ((painter.text as TextSpan).text != cell.char) {
        painter.text = TextSpan(
          text: cell.char,
          style: (painter.text as TextSpan).style,
        );
        painter.layout();
      }
      return painter;
    }

    // Cache size limit check
    if (_cache.length >= maxCacheSize) {
      _cache.clear(); // Simple clear strategy (could use LRU for better performance)
    }

    // Create new TextPainter
    final painter = TextPainter(
      text: TextSpan(
        text: cell.char,
        style: _buildTextStyle(cell, theme),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _cache[hash] = painter;
    return painter;
  }

  /// Computes a hash for the cell's text style.
  ///
  /// The hash is based on colors, font attributes, and theme settings.
  /// The character itself is not included in the hash since we want to
  /// reuse TextPainter for different characters with the same style.
  int _computeStyleHash(TerminalCell cell, TerminalTheme theme) {
    return Object.hash(
      cell.foregroundColor ?? theme.defaultForegroundColor,
      cell.backgroundColor ?? theme.defaultBackgroundColor,
      cell.isBold,
      cell.isItalic,
      cell.isUnderline,
      theme.fontFamily,
      theme.fontSize,
    );
  }

  /// Builds a TextStyle from the cell and theme.
  TextStyle _buildTextStyle(TerminalCell cell, TerminalTheme theme) {
    return TextStyle(
      fontFamily: theme.fontFamily,
      fontSize: theme.fontSize,
      color: cell.foregroundColor ?? theme.defaultForegroundColor,
      backgroundColor: cell.backgroundColor,
      fontWeight: cell.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: cell.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration:
          cell.isUnderline ? TextDecoration.underline : TextDecoration.none,
      height: 1.0, // Use tight height for monospace alignment
      letterSpacing: 0.0, // Ensure consistent character spacing
    );
  }

  /// Clears all cached TextPainter instances.
  ///
  /// This should be called when the theme changes to ensure all cached
  /// painters use the new theme settings.
  void clear() {
    _cache.clear();
  }

  /// Gets the current number of cached TextPainter instances.
  int get cacheSize => _cache.length;
}
