import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/src/core/buffer/cursor.dart';
import 'package:flutter_xterm/src/core/buffer/terminal_buffer.dart';
import 'package:flutter_xterm/src/core/buffer/terminal_cell.dart';

void main() {
  group('TerminalBuffer', () {
    test('creates buffer with specified dimensions', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      expect(buffer.rows, 24);
      expect(buffer.cols, 80);
    });

    test('initializes all cells to empty', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          expect(buffer.getCell(x, y).isEmpty, true);
        }
      }
    });

    test('initializes cursor at origin', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      expect(buffer.cursor.x, 0);
      expect(buffer.cursor.y, 0);
    });

    test('getCell returns correct cell', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      const cell = TerminalCell(char: 'A');
      buffer.setCell(1, 1, cell);

      expect(buffer.getCell(1, 1), cell);
    });

    test('setCell updates cell at position', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      const cell = TerminalCell(char: 'B', isBold: true);

      buffer.setCell(2, 1, cell);
      final retrieved = buffer.getCell(2, 1);

      expect(retrieved.char, 'B');
      expect(retrieved.isBold, true);
    });

    test('getCell throws RangeError for invalid x', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      expect(() => buffer.getCell(-1, 0), throwsRangeError);
      expect(() => buffer.getCell(3, 0), throwsRangeError);
    });

    test('getCell throws RangeError for invalid y', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      expect(() => buffer.getCell(0, -1), throwsRangeError);
      expect(() => buffer.getCell(0, 3), throwsRangeError);
    });

    test('getRow returns all cells in row', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      buffer.setCell(0, 1, const TerminalCell(char: 'A'));
      buffer.setCell(1, 1, const TerminalCell(char: 'B'));
      buffer.setCell(2, 1, const TerminalCell(char: 'C'));

      final row = buffer.getRow(1);

      expect(row.length, 3);
      expect(row[0].char, 'A');
      expect(row[1].char, 'B');
      expect(row[2].char, 'C');
    });

    test('getRow throws RangeError for invalid row', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      expect(() => buffer.getRow(-1), throwsRangeError);
      expect(() => buffer.getRow(3), throwsRangeError);
    });

    test('setRow updates entire row', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      final newRow = [
        const TerminalCell(char: 'X'),
        const TerminalCell(char: 'Y'),
        const TerminalCell(char: 'Z'),
      ];

      buffer.setRow(1, newRow);

      expect(buffer.getCell(0, 1).char, 'X');
      expect(buffer.getCell(1, 1).char, 'Y');
      expect(buffer.getCell(2, 1).char, 'Z');
    });

    test('setRow throws RangeError for invalid row', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      final row = List.generate(3, (_) => TerminalCell.empty());

      expect(() => buffer.setRow(-1, row), throwsRangeError);
      expect(() => buffer.setRow(3, row), throwsRangeError);
    });

    test('setRow throws ArgumentError for wrong length', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);
      final shortRow = [const TerminalCell(char: 'A')];

      expect(() => buffer.setRow(0, shortRow), throwsArgumentError);
    });

    test('clear resets all cells to empty', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      // Fill buffer with non-empty cells
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          buffer.setCell(x, y, const TerminalCell(char: 'X'));
        }
      }

      buffer.clear();

      // Check all cells are empty
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          expect(buffer.getCell(x, y).isEmpty, true);
        }
      }
    });

    test('clearRow clears specified row only', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      // Fill buffer
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          buffer.setCell(x, y, const TerminalCell(char: 'X'));
        }
      }

      buffer.clearRow(1);

      // Row 1 should be empty
      for (int x = 0; x < 3; x++) {
        expect(buffer.getCell(x, 1).isEmpty, true);
      }

      // Other rows should still have 'X'
      expect(buffer.getCell(0, 0).char, 'X');
      expect(buffer.getCell(0, 2).char, 'X');
    });

    test('clearFromCursor clears from cursor to end', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      // Fill buffer
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          buffer.setCell(x, y, const TerminalCell(char: 'X'));
        }
      }

      // Set cursor to (1, 1)
      buffer.setCursor(const Cursor(x: 1, y: 1));
      buffer.clearFromCursor();

      // Check cells before cursor are not cleared
      expect(buffer.getCell(0, 0).char, 'X');
      expect(buffer.getCell(1, 0).char, 'X');
      expect(buffer.getCell(2, 0).char, 'X');
      expect(buffer.getCell(0, 1).char, 'X');

      // Check cells from cursor are cleared
      expect(buffer.getCell(1, 1).isEmpty, true);
      expect(buffer.getCell(2, 1).isEmpty, true);
      expect(buffer.getCell(0, 2).isEmpty, true);
      expect(buffer.getCell(1, 2).isEmpty, true);
      expect(buffer.getCell(2, 2).isEmpty, true);
    });

    test('clearToCursor clears from start to cursor', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      // Fill buffer
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          buffer.setCell(x, y, const TerminalCell(char: 'X'));
        }
      }

      // Set cursor to (1, 1)
      buffer.setCursor(const Cursor(x: 1, y: 1));
      buffer.clearToCursor();

      // Check cells up to and including cursor are cleared
      expect(buffer.getCell(0, 0).isEmpty, true);
      expect(buffer.getCell(1, 0).isEmpty, true);
      expect(buffer.getCell(2, 0).isEmpty, true);
      expect(buffer.getCell(0, 1).isEmpty, true);
      expect(buffer.getCell(1, 1).isEmpty, true);

      // Check cells after cursor are not cleared
      expect(buffer.getCell(2, 1).char, 'X');
      expect(buffer.getCell(0, 2).char, 'X');
    });

    test('scrollUp removes top line and adds empty line at bottom', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      // Set up buffer with identifiable rows
      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(0, 1, const TerminalCell(char: 'B'));
      buffer.setCell(0, 2, const TerminalCell(char: 'C'));

      buffer.scrollUp(1);

      // Row 0 should now have 'B' (was row 1)
      expect(buffer.getCell(0, 0).char, 'B');
      // Row 1 should now have 'C' (was row 2)
      expect(buffer.getCell(0, 1).char, 'C');
      // Row 2 should be empty (newly added)
      expect(buffer.getCell(0, 2).isEmpty, true);
    });

    test('scrollUp with n=2', () {
      final buffer = TerminalBuffer(rows: 4, cols: 2);

      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(0, 1, const TerminalCell(char: 'B'));
      buffer.setCell(0, 2, const TerminalCell(char: 'C'));
      buffer.setCell(0, 3, const TerminalCell(char: 'D'));

      buffer.scrollUp(2);

      expect(buffer.getCell(0, 0).char, 'C');
      expect(buffer.getCell(0, 1).char, 'D');
      expect(buffer.getCell(0, 2).isEmpty, true);
      expect(buffer.getCell(0, 3).isEmpty, true);
    });

    test('scrollDown adds empty line at top and removes bottom line', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(0, 1, const TerminalCell(char: 'B'));
      buffer.setCell(0, 2, const TerminalCell(char: 'C'));

      buffer.scrollDown(1);

      // Row 0 should be empty (newly added)
      expect(buffer.getCell(0, 0).isEmpty, true);
      // Row 1 should now have 'A' (was row 0)
      expect(buffer.getCell(0, 1).char, 'A');
      // Row 2 should now have 'B' (was row 1)
      expect(buffer.getCell(0, 2).char, 'B');
    });

    test('scrollUp with n >= rows clears buffer', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      for (int y = 0; y < 3; y++) {
        buffer.setCell(0, y, const TerminalCell(char: 'X'));
      }

      buffer.scrollUp(3);

      for (int y = 0; y < 3; y++) {
        expect(buffer.getCell(0, y).isEmpty, true);
      }
    });

    test('resize increases buffer size', () {
      final buffer = TerminalBuffer(rows: 2, cols: 2);

      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(1, 1, const TerminalCell(char: 'B'));

      buffer.resize(3, 3);

      // Old content preserved
      expect(buffer.getCell(0, 0).char, 'A');
      expect(buffer.getCell(1, 1).char, 'B');

      // New cells are empty
      expect(buffer.getCell(2, 2).isEmpty, true);
    });

    test('resize decreases buffer size', () {
      final buffer = TerminalBuffer(rows: 3, cols: 3);

      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(2, 2, const TerminalCell(char: 'Z'));

      buffer.resize(2, 2);

      // Content within new bounds preserved
      expect(buffer.getCell(0, 0).char, 'A');

      // Cell at (2,2) is now out of bounds
      expect(() => buffer.getCell(2, 2), throwsRangeError);
    });

    test('setCursor clamps to valid bounds', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      buffer.setCursor(const Cursor(x: 100, y: 50));

      expect(buffer.cursor.x, 79); // maxX - 1
      expect(buffer.cursor.y, 23); // maxY - 1
    });

    test('setCursor with negative values clamps to 0', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      buffer.setCursor(const Cursor(x: -5, y: -10));

      expect(buffer.cursor.x, 0);
      expect(buffer.cursor.y, 0);
    });

    test('moveCursorRelative moves cursor', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      buffer.setCursor(const Cursor(x: 10, y: 10));
      buffer.moveCursorRelative(5, 3);

      expect(buffer.cursor.x, 15);
      expect(buffer.cursor.y, 13);
    });

    test('moveCursorRelative clamps to bounds', () {
      final buffer = TerminalBuffer(rows: 24, cols: 80);

      buffer.setCursor(const Cursor(x: 70, y: 20));
      buffer.moveCursorRelative(20, 10);

      expect(buffer.cursor.x, 79);
      expect(buffer.cursor.y, 23);
    });

    test('toString returns buffer content as string', () {
      final buffer = TerminalBuffer(rows: 2, cols: 3);

      buffer.setCell(0, 0, const TerminalCell(char: 'A'));
      buffer.setCell(1, 0, const TerminalCell(char: 'B'));
      buffer.setCell(2, 0, const TerminalCell(char: 'C'));
      buffer.setCell(0, 1, const TerminalCell(char: 'D'));
      buffer.setCell(1, 1, const TerminalCell(char: 'E'));
      buffer.setCell(2, 1, const TerminalCell(char: 'F'));

      final str = buffer.toString();

      expect(str, 'ABC\nDEF');
    });
  });
}
