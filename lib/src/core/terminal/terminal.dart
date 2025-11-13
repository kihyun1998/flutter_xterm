import 'package:flutter/material.dart';
import '../buffer/cursor.dart';
import '../buffer/terminal_buffer.dart';
import '../buffer/terminal_cell.dart';
import '../parser/escape_sequence_parser.dart';
import '../parser/ansi_command.dart';
import '../parser/csi_handler.dart';
import '../parser/osc_handler.dart';
import '../../utils/constants.dart';

/// The main terminal emulator class.
///
/// This class manages the terminal state, handles text output,
/// processes control characters, and parses ANSI escape sequences.
class Terminal {
  /// The current terminal buffer (may switch to alternate buffer).
  TerminalBuffer buffer;

  /// The ANSI escape sequence parser.
  final EscapeSequenceParser _parser = EscapeSequenceParser();

  /// The current text style applied to new characters.
  TerminalCell _currentStyle = TerminalCell.empty();

  /// The main screen buffer.
  late TerminalBuffer _mainBuffer;

  /// The alternate screen buffer.
  TerminalBuffer? _alternateBuffer;

  /// Whether we're currently using the alternate buffer.
  bool _usingAlternateBuffer = false;

  /// Terminal title (set by OSC sequences).
  String _title = '';

  /// Terminal icon name (set by OSC sequences).
  String _iconName = '';

  /// Saved cursor position (for save/restore).
  Cursor? _savedCursor;

  /// Scrolling region (top and bottom margins).
  int _scrollTop = 0;
  int _scrollBottom = 0;

  /// Terminal modes.
  bool _cursorKeysMode = false;
  bool _bracketedPasteMode = false;
  bool _insertMode = false;
  bool _newLineMode = false;

  /// Default colors (can be set by OSC sequences).
  Color? _defaultForegroundColor;
  Color? _defaultBackgroundColor;

  /// Custom color palette (can be modified by OSC sequences).
  final Map<int, int> _customPalette = {};

  /// Creates a terminal with the specified dimensions.
  Terminal({
    required int rows,
    required int cols,
  })  : buffer = TerminalBuffer(rows: rows, cols: cols),
        _mainBuffer = TerminalBuffer(rows: rows, cols: cols) {
    _scrollBottom = rows - 1;
  }

  /// Gets the number of rows in the terminal.
  int get rows => buffer.rows;

  /// Gets the number of columns in the terminal.
  int get cols => buffer.cols;

  /// Gets the current cursor position.
  Cursor get cursor => buffer.cursor;

  /// Gets the terminal title.
  String get title => _title;

  /// Gets the terminal icon name.
  String get iconName => _iconName;

  /// Writes text to the terminal.
  ///
  /// This method parses ANSI escape sequences and processes the text
  /// accordingly, handling control characters, cursor movements, colors, etc.
  void write(String text) {
    final commands = _parser.parse(text);

    for (final cmd in commands) {
      if (cmd is PrintCommand) {
        _writeChar(cmd.char);
      } else if (cmd is ControlCommand) {
        _handleControlChar(cmd.char);
      } else if (cmd is CsiCommand) {
        CsiHandler.execute(this, cmd);
      } else if (cmd is OscCommand) {
        OscHandler.execute(this, cmd);
      }
    }
  }

  /// Handles control characters (\n, \r, \t, \b, etc.).
  void _handleControlChar(String char) {
    switch (char) {
      case '\n':
        _handleNewline();
        break;
      case '\r':
        _handleCarriageReturn();
        break;
      case '\t':
        _handleTab();
        break;
      case '\b':
        _handleBackspace();
        break;
      // Other control characters can be added here
    }
  }

  /// Writes a single character at the current cursor position.
  void _writeChar(String char) {
    final cursor = buffer.cursor;

    if (_insertMode) {
      // Insert mode: shift characters to the right
      insertChars(1);
    }

    // Write the character with current style
    buffer.setCell(
      cursor.x,
      cursor.y,
      _currentStyle.copyWith(char: char),
    );

    // Advance cursor
    _advanceCursor();
  }

  /// Advances the cursor to the next position.
  ///
  /// Handles automatic line wrapping and scrolling when necessary.
  void _advanceCursor() {
    var cursor = buffer.cursor;
    int newX = cursor.x + 1;
    int newY = cursor.y;

    // Check for line wrap
    if (newX >= cols) {
      newX = 0;
      newY++;
    }

    // Check if we need to scroll
    if (newY > _scrollBottom) {
      _scrollUpRegion(1);
      newY = _scrollBottom;
    }

    buffer.setCursor(cursor.copyWith(x: newX, y: newY));
  }

  /// Handles newline character (\n).
  ///
  /// Moves the cursor to the beginning of the next line (if newLineMode is true)
  /// or just moves down (if newLineMode is false).
  void _handleNewline() {
    var cursor = buffer.cursor;
    int newY = cursor.y + 1;
    int newX = _newLineMode ? 0 : cursor.x;

    // Check if we need to scroll
    if (newY > _scrollBottom) {
      _scrollUpRegion(1);
      newY = _scrollBottom;
    }

    buffer.setCursor(cursor.copyWith(x: newX, y: newY));
  }

  /// Handles carriage return character (\r).
  ///
  /// Moves the cursor to the beginning of the current line.
  void _handleCarriageReturn() {
    var cursor = buffer.cursor;
    buffer.setCursor(cursor.copyWith(x: 0));
  }

  /// Handles tab character (\t).
  ///
  /// Moves the cursor to the next tab stop (multiple of tabSize).
  void _handleTab() {
    var cursor = buffer.cursor;
    int nextTabStop = ((cursor.x ~/ tabSize) + 1) * tabSize;

    if (nextTabStop >= cols) {
      // Tab at end of line wraps to next line
      _handleNewline();
    } else {
      buffer.setCursor(cursor.copyWith(x: nextTabStop));
    }
  }

  /// Handles backspace character (\b).
  ///
  /// Moves the cursor one position to the left (doesn't delete).
  void _handleBackspace() {
    var cursor = buffer.cursor;

    if (cursor.x > 0) {
      buffer.setCursor(cursor.copyWith(x: cursor.x - 1));
    }
  }

  // === Cursor Movement Methods ===

  /// Moves the cursor up by [n] rows.
  void moveCursorUp(int n) {
    final cursor = buffer.cursor;
    final newY = (cursor.y - n).clamp(_scrollTop, _scrollBottom);
    buffer.setCursor(cursor.copyWith(y: newY));
  }

  /// Moves the cursor down by [n] rows.
  void moveCursorDown(int n) {
    final cursor = buffer.cursor;
    final newY = (cursor.y + n).clamp(_scrollTop, _scrollBottom);
    buffer.setCursor(cursor.copyWith(y: newY));
  }

  /// Moves the cursor right by [n] columns.
  void moveCursorRight(int n) {
    final cursor = buffer.cursor;
    final newX = (cursor.x + n).clamp(0, cols - 1);
    buffer.setCursor(cursor.copyWith(x: newX));
  }

  /// Moves the cursor left by [n] columns.
  void moveCursorLeft(int n) {
    final cursor = buffer.cursor;
    final newX = (cursor.x - n).clamp(0, cols - 1);
    buffer.setCursor(cursor.copyWith(x: newX));
  }

  /// Sets the cursor position to the specified column and row.
  void setCursorPosition(int x, int y) {
    buffer.setCursor(Cursor(
      x: x.clamp(0, cols - 1),
      y: y.clamp(0, rows - 1),
      isVisible: buffer.cursor.isVisible,
      style: buffer.cursor.style,
    ));
  }

  /// Sets the cursor column.
  void setCursorColumn(int x) {
    final cursor = buffer.cursor;
    buffer.setCursor(cursor.copyWith(x: x.clamp(0, cols - 1)));
  }

  /// Sets the cursor row.
  void setCursorRow(int y) {
    final cursor = buffer.cursor;
    buffer.setCursor(cursor.copyWith(y: y.clamp(0, rows - 1)));
  }

  // === Screen Manipulation Methods ===

  /// Erases from the cursor to the end of the screen.
  void eraseDisplayBelow() {
    buffer.clearFromCursor();
  }

  /// Erases from the beginning of the screen to the cursor.
  void eraseDisplayAbove() {
    buffer.clearToCursor();
  }

  /// Erases the entire screen.
  void eraseDisplay() {
    buffer.clear();
  }

  /// Erases from the cursor to the end of the line.
  void eraseLineRight() {
    final cursor = buffer.cursor;
    for (int x = cursor.x; x < cols; x++) {
      buffer.setCell(x, cursor.y, TerminalCell.empty());
    }
  }

  /// Erases from the beginning of the line to the cursor.
  void eraseLineLeft() {
    final cursor = buffer.cursor;
    for (int x = 0; x <= cursor.x; x++) {
      buffer.setCell(x, cursor.y, TerminalCell.empty());
    }
  }

  /// Erases the entire line.
  void eraseLine() {
    buffer.clearRow(buffer.cursor.y);
  }

  /// Scrolls the screen up by [n] lines.
  void scrollUp(int n) {
    buffer.scrollUp(n);
  }

  /// Scrolls the screen down by [n] lines.
  void scrollDown(int n) {
    buffer.scrollDown(n);
  }

  /// Scrolls the scrolling region up by [n] lines.
  void _scrollUpRegion(int n) {
    // For now, just scroll the entire buffer
    // TODO: Implement proper scrolling region support
    buffer.scrollUp(n);
  }

  /// Inserts [n] blank lines at the cursor position.
  void insertLines(int n) {
    final cursor = buffer.cursor;
    for (int i = 0; i < n && cursor.y + i < rows; i++) {
      // Shift lines down
      for (int y = rows - 1; y > cursor.y; y--) {
        buffer.setRow(y, buffer.getRow(y - 1));
      }
      // Clear the cursor line
      buffer.clearRow(cursor.y);
    }
  }

  /// Deletes [n] lines at the cursor position.
  void deleteLines(int n) {
    final cursor = buffer.cursor;
    for (int i = 0; i < n && cursor.y < rows; i++) {
      // Shift lines up
      for (int y = cursor.y; y < rows - 1; y++) {
        buffer.setRow(y, buffer.getRow(y + 1));
      }
      // Clear the last line
      buffer.clearRow(rows - 1);
    }
  }

  /// Inserts [n] blank characters at the cursor position.
  void insertChars(int n) {
    final cursor = buffer.cursor;
    final row = buffer.getRow(cursor.y);

    // Shift characters to the right
    for (int x = cols - 1; x >= cursor.x + n; x--) {
      if (x - n >= 0) {
        buffer.setCell(x, cursor.y, row[x - n]);
      }
    }

    // Clear the inserted positions
    for (int x = cursor.x; x < cursor.x + n && x < cols; x++) {
      buffer.setCell(x, cursor.y, TerminalCell.empty());
    }
  }

  /// Deletes [n] characters at the cursor position.
  void deleteChars(int n) {
    final cursor = buffer.cursor;
    final row = buffer.getRow(cursor.y);

    // Shift characters to the left
    for (int x = cursor.x; x < cols - n; x++) {
      buffer.setCell(x, cursor.y, row[x + n]);
    }

    // Clear the end of the line
    for (int x = cols - n; x < cols; x++) {
      buffer.setCell(x, cursor.y, TerminalCell.empty());
    }
  }

  /// Erases [n] characters at the cursor position.
  void eraseChars(int n) {
    final cursor = buffer.cursor;
    for (int x = cursor.x; x < cursor.x + n && x < cols; x++) {
      buffer.setCell(x, cursor.y, TerminalCell.empty());
    }
  }

  // === Style Methods ===

  /// Gets the current text style.
  TerminalCell getCurrentStyle() => _currentStyle;

  /// Sets the current text style.
  ///
  /// This style will be applied to all subsequently written characters.
  void setStyle(TerminalCell style) {
    _currentStyle = style;
  }

  /// Resets the text style to default.
  void resetStyle() {
    _currentStyle = TerminalCell.empty();
  }

  // === Buffer Management ===

  /// Switches to the alternate screen buffer.
  void useAlternateBuffer(bool use) {
    if (use && !_usingAlternateBuffer) {
      // Save main buffer and switch to alternate
      _alternateBuffer = TerminalBuffer(rows: rows, cols: cols);
      buffer = _alternateBuffer!;
      _usingAlternateBuffer = true;
    } else if (!use && _usingAlternateBuffer) {
      // Restore main buffer
      buffer = _mainBuffer;
      _alternateBuffer = null;
      _usingAlternateBuffer = false;
    }
  }

  // === Cursor Visibility ===

  /// Shows or hides the cursor.
  void showCursor(bool visible) {
    buffer.setCursor(buffer.cursor.copyWith(isVisible: visible));
  }

  // === Title and Icon ===

  /// Sets the terminal title.
  void setTitle(String title) {
    _title = title;
  }

  /// Sets the terminal icon name.
  void setIconName(String name) {
    _iconName = name;
  }

  // === Mode Settings ===

  /// Sets the cursor keys mode (application vs normal).
  void setCursorKeysMode(bool enabled) {
    _cursorKeysMode = enabled;
  }

  /// Gets the cursor keys mode.
  bool get cursorKeysMode => _cursorKeysMode;

  /// Sets the bracketed paste mode.
  void setBracketedPasteMode(bool enabled) {
    _bracketedPasteMode = enabled;
  }

  /// Gets the bracketed paste mode.
  bool get bracketedPasteMode => _bracketedPasteMode;

  /// Sets the insert mode.
  void setInsertMode(bool enabled) {
    _insertMode = enabled;
  }

  /// Gets the insert mode.
  bool get insertMode => _insertMode;

  /// Sets the new line mode.
  void setNewLineMode(bool enabled) {
    _newLineMode = enabled;
  }

  /// Gets the new line mode.
  bool get newLineMode => _newLineMode;

  // === Scrolling Region ===

  /// Sets the scrolling region (top and bottom margins).
  void setScrollRegion(int top, int bottom) {
    _scrollTop = top.clamp(0, rows - 1);
    _scrollBottom = bottom.clamp(_scrollTop, rows - 1);
  }

  // === Cursor Save/Restore ===

  /// Saves the current cursor position.
  void saveCursor() {
    _savedCursor = buffer.cursor;
  }

  /// Restores the saved cursor position.
  void restoreCursor() {
    if (_savedCursor != null) {
      buffer.setCursor(_savedCursor!);
    }
  }

  // === Color Palette ===

  /// Sets a custom color in the palette.
  void setPaletteColor(int index, int color) {
    if (index >= 0 && index < 256) {
      _customPalette[index] = color;
    }
  }

  /// Gets a custom color from the palette.
  int? getPaletteColor(int index) {
    return _customPalette[index];
  }

  /// Sets the default foreground color.
  void setDefaultForegroundColor(Color color) {
    _defaultForegroundColor = color;
  }

  /// Sets the default background color.
  void setDefaultBackgroundColor(Color color) {
    _defaultBackgroundColor = color;
  }

  // === Clipboard (OSC 52) ===

  /// Stores clipboard data (for OSC 52 sequences).
  ///
  /// This is a placeholder - actual clipboard integration would require
  /// platform-specific code.
  void setClipboardData(String clipboardType, String base64Data) {
    // TODO: Implement actual clipboard integration
  }

  // === Utility Methods ===

  /// Clears the entire terminal screen.
  void clear() {
    buffer.clear();
    buffer.setCursor(const Cursor());
  }

  /// Resets the terminal to its initial state.
  ///
  /// Clears the buffer, resets cursor, resets style, and resets modes.
  void reset() {
    buffer.clear();
    buffer.setCursor(const Cursor());
    resetStyle();
    _parser.reset();
    _scrollTop = 0;
    _scrollBottom = rows - 1;
    _cursorKeysMode = false;
    _bracketedPasteMode = false;
    _insertMode = false;
    _newLineMode = false;
    _title = '';
    _iconName = '';
    _savedCursor = null;
  }

  /// Resizes the terminal to new dimensions.
  void resize(int newRows, int newCols) {
    buffer.resize(newRows, newCols);
    _mainBuffer.resize(newRows, newCols);
    _alternateBuffer?.resize(newRows, newCols);
    _scrollBottom = newRows - 1;
  }
}
