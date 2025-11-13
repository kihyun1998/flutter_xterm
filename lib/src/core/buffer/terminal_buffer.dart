import 'cursor.dart';
import 'terminal_cell.dart';

/// Manages the 2D grid of terminal cells.
///
/// The buffer represents the visible terminal screen with [rows] x [cols] cells.
/// It also tracks the cursor position.
class TerminalBuffer {
  /// Number of rows in the buffer.
  int rows;

  /// Number of columns in the buffer.
  int cols;

  /// The 2D array of cells [row][col].
  late List<List<TerminalCell>> _cells;

  /// The current cursor position.
  Cursor _cursor;

  /// Creates a terminal buffer with the specified dimensions.
  TerminalBuffer({
    required this.rows,
    required this.cols,
  }) : _cursor = const Cursor() {
    _initializeCells();
  }

  /// Gets the current cursor.
  Cursor get cursor => _cursor;

  /// Initializes all cells to empty cells.
  void _initializeCells() {
    _cells = List.generate(
      rows,
      (_) => List.generate(cols, (_) => TerminalCell.empty()),
    );
  }

  /// Gets the cell at the specified position.
  ///
  /// Throws [RangeError] if position is out of bounds.
  TerminalCell getCell(int x, int y) {
    _validatePosition(x, y);
    return _cells[y][x];
  }

  /// Sets the cell at the specified position.
  ///
  /// Throws [RangeError] if position is out of bounds.
  void setCell(int x, int y, TerminalCell cell) {
    _validatePosition(x, y);
    _cells[y][x] = cell;
  }

  /// Gets all cells in the specified row.
  ///
  /// Throws [RangeError] if row is out of bounds.
  List<TerminalCell> getRow(int y) {
    if (y < 0 || y >= rows) {
      throw RangeError('Row $y is out of range [0, $rows)');
    }
    return List.from(_cells[y]);
  }

  /// Sets all cells in the specified row.
  ///
  /// Throws [RangeError] if row is out of bounds.
  /// Throws [ArgumentError] if the cells list length doesn't match cols.
  void setRow(int y, List<TerminalCell> cells) {
    if (y < 0 || y >= rows) {
      throw RangeError('Row $y is out of range [0, $rows)');
    }
    if (cells.length != cols) {
      throw ArgumentError(
          'Expected $cols cells but got ${cells.length}');
    }
    _cells[y] = List.from(cells);
  }

  /// Clears the entire buffer (fills with empty cells).
  void clear() {
    _initializeCells();
  }

  /// Clears the specified row.
  ///
  /// Throws [RangeError] if row is out of bounds.
  void clearRow(int y) {
    if (y < 0 || y >= rows) {
      throw RangeError('Row $y is out of range [0, $rows)');
    }
    _cells[y] = List.generate(cols, (_) => TerminalCell.empty());
  }

  /// Clears from the cursor position to the end of the buffer.
  void clearFromCursor() {
    final cursorX = _cursor.x;
    final cursorY = _cursor.y;

    // Clear from cursor to end of current line
    for (int x = cursorX; x < cols; x++) {
      if (cursorY >= 0 && cursorY < rows) {
        _cells[cursorY][x] = TerminalCell.empty();
      }
    }

    // Clear all lines after cursor
    for (int y = cursorY + 1; y < rows; y++) {
      clearRow(y);
    }
  }

  /// Clears from the beginning of the buffer to the cursor position.
  void clearToCursor() {
    final cursorX = _cursor.x;
    final cursorY = _cursor.y;

    // Clear all lines before cursor
    for (int y = 0; y < cursorY && y < rows; y++) {
      clearRow(y);
    }

    // Clear from start of current line to cursor
    if (cursorY >= 0 && cursorY < rows) {
      for (int x = 0; x <= cursorX && x < cols; x++) {
        _cells[cursorY][x] = TerminalCell.empty();
      }
    }
  }

  /// Scrolls the buffer up by [n] lines.
  ///
  /// The top [n] lines are removed, and [n] empty lines are added at the bottom.
  void scrollUp(int n) {
    if (n <= 0 || n >= rows) {
      if (n >= rows) {
        clear();
      }
      return;
    }

    // Remove top n lines and add n empty lines at bottom
    _cells = [
      ..._cells.sublist(n),
      ...List.generate(
        n,
        (_) => List.generate(cols, (_) => TerminalCell.empty()),
      ),
    ];
  }

  /// Scrolls the buffer down by [n] lines.
  ///
  /// The bottom [n] lines are removed, and [n] empty lines are added at the top.
  void scrollDown(int n) {
    if (n <= 0 || n >= rows) {
      if (n >= rows) {
        clear();
      }
      return;
    }

    // Add n empty lines at top and remove bottom n lines
    _cells = [
      ...List.generate(
        n,
        (_) => List.generate(cols, (_) => TerminalCell.empty()),
      ),
      ..._cells.sublist(0, rows - n),
    ];
  }

  /// Resizes the buffer to the new dimensions.
  ///
  /// Existing content is preserved as much as possible.
  /// If the new size is smaller, content is truncated.
  /// If the new size is larger, new cells are filled with empty cells.
  void resize(int newRows, int newCols) {
    final newCells = List.generate(
      newRows,
      (y) => List.generate(
        newCols,
        (x) {
          if (y < rows && x < cols) {
            return _cells[y][x];
          }
          return TerminalCell.empty();
        },
      ),
    );

    _cells = newCells;
    rows = newRows;
    cols = newCols;
  }

  /// Sets the cursor position.
  ///
  /// The cursor is automatically clamped to valid bounds.
  void setCursor(Cursor cursor) {
    _cursor = cursor.clamp(cols, rows);
  }

  /// Moves the cursor by the specified relative offset.
  ///
  /// The cursor is automatically clamped to valid bounds.
  void moveCursorRelative(int dx, int dy) {
    _cursor = _cursor.copyWith(
      x: _cursor.x + dx,
      y: _cursor.y + dy,
    ).clamp(cols, rows);
  }

  /// Validates that the position is within buffer bounds.
  void _validatePosition(int x, int y) {
    if (x < 0 || x >= cols) {
      throw RangeError('Column $x is out of range [0, $cols)');
    }
    if (y < 0 || y >= rows) {
      throw RangeError('Row $y is out of range [0, $rows)');
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        buffer.write(_cells[y][x].char);
      }
      if (y < rows - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}
