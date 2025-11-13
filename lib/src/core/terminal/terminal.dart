import '../buffer/cursor.dart';
import '../buffer/terminal_buffer.dart';
import '../buffer/terminal_cell.dart';
import '../../utils/constants.dart';

/// The main terminal emulator class.
///
/// This class manages the terminal state, handles text output,
/// and processes control characters.
class Terminal {
  /// The main terminal buffer.
  final TerminalBuffer buffer;

  /// The current text style applied to new characters.
  TerminalCell _currentStyle = TerminalCell.empty();

  /// Creates a terminal with the specified dimensions.
  Terminal({
    required int rows,
    required int cols,
  }) : buffer = TerminalBuffer(rows: rows, cols: cols);

  /// Gets the number of rows in the terminal.
  int get rows => buffer.rows;

  /// Gets the number of columns in the terminal.
  int get cols => buffer.cols;

  /// Gets the current cursor position.
  Cursor get cursor => buffer.cursor;

  /// Writes text to the terminal.
  ///
  /// This method processes the text character by character,
  /// handling control characters like \n, \r, \t, and \b.
  void write(String text) {
    for (int i = 0; i < text.length; i++) {
      final char = text[i];

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
        default:
          _writeChar(char);
      }
    }
  }

  /// Writes a single character at the current cursor position.
  void _writeChar(String char) {
    final cursor = buffer.cursor;

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
    if (newY >= rows) {
      buffer.scrollUp(1);
      newY = rows - 1;
    }

    buffer.setCursor(cursor.copyWith(x: newX, y: newY));
  }

  /// Handles newline character (\n).
  ///
  /// Moves the cursor to the beginning of the next line.
  void _handleNewline() {
    var cursor = buffer.cursor;
    int newY = cursor.y + 1;

    // Check if we need to scroll
    if (newY >= rows) {
      buffer.scrollUp(1);
      newY = rows - 1;
    }

    buffer.setCursor(cursor.copyWith(x: 0, y: newY));
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

  /// Clears the entire terminal screen.
  void clear() {
    buffer.clear();
    buffer.setCursor(const Cursor());
  }

  /// Resets the terminal to its initial state.
  ///
  /// Clears the buffer, resets cursor, and resets style.
  void reset() {
    buffer.clear();
    buffer.setCursor(const Cursor());
    resetStyle();
  }

  /// Resizes the terminal to new dimensions.
  void resize(int newRows, int newCols) {
    buffer.resize(newRows, newCols);
    // Cursor is automatically clamped by the buffer
  }
}
