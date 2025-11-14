import 'package:flutter/material.dart';
import '../core/terminal/terminal.dart';
import 'terminal_theme.dart';
import 'terminal_painter.dart';

/// A widget that displays a terminal.
///
/// This widget renders the terminal buffer with proper text styling,
/// colors, and a blinking cursor. It uses [CustomPaint] for efficient
/// rendering.
///
/// Example:
/// ```dart
/// final terminal = Terminal(rows: 24, cols: 80);
/// terminal.write('Hello, World!\n');
///
/// TerminalView(
///   terminal: terminal,
///   theme: TerminalTheme.dark(),
/// )
/// ```
class TerminalView extends StatefulWidget {
  /// The terminal instance to display.
  final Terminal terminal;

  /// Theme configuration for rendering.
  /// If null, uses [TerminalTheme.dark()].
  final TerminalTheme? theme;

  /// Creates a terminal view widget.
  const TerminalView({
    super.key,
    required this.terminal,
    this.theme,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView>
    with SingleTickerProviderStateMixin {
  /// Animation controller for cursor blinking.
  late AnimationController _cursorBlinkController;

  /// Whether to show the cursor (toggles for blinking effect).
  bool _showCursor = true;

  /// Effective theme (uses provided theme or default dark theme).
  late TerminalTheme _effectiveTheme;

  @override
  void initState() {
    super.initState();

    _effectiveTheme = widget.theme ?? TerminalTheme.dark();

    // Set up cursor blinking animation
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: _effectiveTheme.cursorBlinkInterval,
    )..addStatusListener(_onCursorBlinkTick);

    _cursorBlinkController.forward();
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update theme if changed
    if (widget.theme != oldWidget.theme) {
      setState(() {
        _effectiveTheme = widget.theme ?? TerminalTheme.dark();
        _cursorBlinkController.duration = _effectiveTheme.cursorBlinkInterval;
      });
    }
  }

  @override
  void dispose() {
    _cursorBlinkController.removeStatusListener(_onCursorBlinkTick);
    _cursorBlinkController.dispose();
    super.dispose();
  }

  /// Handles cursor blink animation ticks.
  void _onCursorBlinkTick(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _showCursor = !_showCursor;
      });
      _cursorBlinkController.reset();
      _cursorBlinkController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = _effectiveTheme.cellSize;

    // Calculate terminal size based on rows, cols, and padding
    final terminalSize = Size(
      _effectiveTheme.padding.horizontal +
          widget.terminal.cols * cellSize.width,
      _effectiveTheme.padding.vertical +
          widget.terminal.rows * cellSize.height,
    );

    return Container(
      width: terminalSize.width,
      height: terminalSize.height,
      color: _effectiveTheme.defaultBackgroundColor,
      child: CustomPaint(
        size: terminalSize,
        painter: TerminalPainter(
          terminal: widget.terminal,
          theme: _effectiveTheme,
          showCursor: _showCursor,
        ),
      ),
    );
  }
}
