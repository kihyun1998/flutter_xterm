import 'package:flutter/material.dart';

import '../core/buffer/cursor.dart';
import '../core/terminal/terminal.dart';
import 'terminal_theme.dart';
import 'text_style_cache.dart';

/// Custom painter for rendering the terminal content.
///
/// This painter draws the terminal buffer, including background colors,
/// text with styling, and the cursor.
class TerminalPainter extends CustomPainter {
  /// The terminal instance to render.
  final Terminal terminal;

  /// Theme configuration for rendering.
  final TerminalTheme theme;

  /// Whether to show the cursor (used for blinking animation).
  final bool showCursor;

  /// Cache for TextPainter instances.
  final TextStyleCache _textCache = TextStyleCache();

  /// Creates a terminal painter.
  TerminalPainter({
    required this.terminal,
    required this.theme,
    this.showCursor = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = theme.cellSize;

    // 1. Draw terminal background
    _drawBackground(canvas, size);

    // 2. Draw each cell (background + text)
    for (int y = 0; y < terminal.rows; y++) {
      for (int x = 0; x < terminal.cols; x++) {
        final cell = terminal.buffer.getCell(x, y);
        final offset = Offset(
          theme.padding.left + x * cellSize.width,
          theme.padding.top + y * cellSize.height,
        );

        // Draw cell background if specified
        if (cell.backgroundColor != null) {
          _drawCellBackground(canvas, offset, cellSize, cell.backgroundColor!);
        }

        // Draw text (skip spaces for performance)
        if (cell.char != ' ' && cell.char.isNotEmpty) {
          _drawText(canvas, offset, cell);
        }
      }
    }

    // 3. Draw cursor
    if (showCursor && terminal.cursor.isVisible) {
      _drawCursor(canvas, cellSize);
    }
  }

  /// Draws the terminal background.
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.defaultBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// Draws the background of a single cell.
  void _drawCellBackground(
    Canvas canvas,
    Offset offset,
    Size cellSize,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(offset & cellSize, paint);
  }

  /// Draws the text of a single cell.
  void _drawText(Canvas canvas, Offset offset, cell) {
    final textPainter = _textCache.getPainter(cell, theme);
    textPainter.paint(canvas, offset);
  }

  /// Draws the cursor at the current cursor position.
  void _drawCursor(Canvas canvas, Size cellSize) {
    final cursor = terminal.cursor;
    final offset = Offset(
      theme.padding.left + cursor.x * cellSize.width,
      theme.padding.top + cursor.y * cellSize.height,
    );

    final paint = Paint()
      ..color = theme.cursorColor
      ..style = PaintingStyle.fill;

    switch (theme.cursorStyle) {
      case CursorStyle.block:
        // Block cursor: fill entire cell
        canvas.drawRect(offset & cellSize, paint);
        break;

      case CursorStyle.underline:
        // Underline cursor: draw 2px line at bottom
        canvas.drawRect(
          Rect.fromLTWH(
            offset.dx,
            offset.dy + cellSize.height - 2,
            cellSize.width,
            2,
          ),
          paint,
        );
        break;

      case CursorStyle.bar:
        // Bar cursor: draw 2px line at left
        canvas.drawRect(
          Rect.fromLTWH(offset.dx, offset.dy, 2, cellSize.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(TerminalPainter oldDelegate) {
    // Repaint if terminal, theme, or cursor visibility changed
    return oldDelegate.terminal != terminal ||
        oldDelegate.theme != theme ||
        oldDelegate.showCursor != showCursor;
  }
}
