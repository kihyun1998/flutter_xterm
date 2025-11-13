import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/src/core/terminal/terminal.dart';
import 'package:flutter_xterm/src/core/buffer/terminal_cell.dart';

void main() {
  group('Terminal', () {
    test('creates terminal with specified dimensions', () {
      final terminal = Terminal(rows: 24, cols: 80);

      expect(terminal.rows, 24);
      expect(terminal.cols, 80);
    });

    test('initializes with cursor at origin', () {
      final terminal = Terminal(rows: 24, cols: 80);

      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 0);
    });

    test('write single character', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('A');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.cursor.x, 1);
      expect(terminal.cursor.y, 0);
    });

    test('write multiple characters', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('Hello');

      expect(terminal.buffer.getCell(0, 0).char, 'H');
      expect(terminal.buffer.getCell(1, 0).char, 'e');
      expect(terminal.buffer.getCell(2, 0).char, 'l');
      expect(terminal.buffer.getCell(3, 0).char, 'l');
      expect(terminal.buffer.getCell(4, 0).char, 'o');
      expect(terminal.cursor.x, 5);
    });

    test('newline moves cursor to next line', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('A\nB');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.buffer.getCell(0, 1).char, 'B');
      expect(terminal.cursor.x, 1);
      expect(terminal.cursor.y, 1);
    });

    test('carriage return moves cursor to line start', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('ABC\rX');

      expect(terminal.buffer.getCell(0, 0).char, 'X');
      expect(terminal.buffer.getCell(1, 0).char, 'B');
      expect(terminal.buffer.getCell(2, 0).char, 'C');
    });

    test('tab moves cursor to next tab stop', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('A\tB');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.buffer.getCell(8, 0).char, 'B');
      expect(terminal.cursor.x, 9);
    });

    test('tab from position 5 moves to position 8', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('12345\tX');

      expect(terminal.buffer.getCell(8, 0).char, 'X');
    });

    test('tab at column 16 moves to column 24', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('0123456789012345\tX');

      expect(terminal.buffer.getCell(24, 0).char, 'X');
    });

    test('backspace moves cursor left', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('ABC\bX');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.buffer.getCell(1, 0).char, 'B');
      expect(terminal.buffer.getCell(2, 0).char, 'X');
    });

    test('backspace at column 0 does nothing', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('\bA');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.cursor.x, 1);
    });

    test('automatic line wrap at end of line', () {
      final terminal = Terminal(rows: 24, cols: 10);

      terminal.write('0123456789X');

      expect(terminal.buffer.getCell(9, 0).char, '9');
      expect(terminal.buffer.getCell(0, 1).char, 'X');
      expect(terminal.cursor.x, 1);
      expect(terminal.cursor.y, 1);
    });

    test('scroll when writing past bottom', () {
      final terminal = Terminal(rows: 3, cols: 10);

      // Fill all 3 lines
      terminal.write('Line0\n');
      terminal.write('Line1\n');
      terminal.write('Line2\n');
      terminal.write('Line3');

      // First line should be scrolled away
      expect(terminal.buffer.getCell(0, 0).char, 'L'); // Line1
      expect(terminal.buffer.getCell(0, 1).char, 'L'); // Line2
      expect(terminal.buffer.getCell(0, 2).char, 'L'); // Line3
    });

    test('setStyle applies style to written characters', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.setStyle(const TerminalCell(
        foregroundColor: Colors.red,
        isBold: true,
      ));
      terminal.write('X');

      final cell = terminal.buffer.getCell(0, 0);
      expect(cell.char, 'X');
      expect(cell.foregroundColor, Colors.red);
      expect(cell.isBold, true);
    });

    test('resetStyle clears current style', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.setStyle(const TerminalCell(
        foregroundColor: Colors.red,
        isBold: true,
      ));
      terminal.write('A');

      terminal.resetStyle();
      terminal.write('B');

      final cellA = terminal.buffer.getCell(0, 0);
      final cellB = terminal.buffer.getCell(1, 0);

      expect(cellA.foregroundColor, Colors.red);
      expect(cellA.isBold, true);
      expect(cellB.foregroundColor, isNull);
      expect(cellB.isBold, false);
    });

    test('clear resets buffer and cursor', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('Hello World');
      terminal.clear();

      expect(terminal.buffer.getCell(0, 0).isEmpty, true);
      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 0);
    });

    test('reset clears buffer, cursor, and style', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.setStyle(const TerminalCell(isBold: true));
      terminal.write('Test');
      terminal.reset();

      expect(terminal.buffer.getCell(0, 0).isEmpty, true);
      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 0);

      // Write after reset should use default style
      terminal.write('X');
      final cell = terminal.buffer.getCell(0, 0);
      expect(cell.isBold, false);
    });

    test('resize changes terminal dimensions', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('Test');
      terminal.resize(30, 100);

      expect(terminal.rows, 30);
      expect(terminal.cols, 100);
      // Content should be preserved
      expect(terminal.buffer.getCell(0, 0).char, 'T');
    });

    test('tab at end of line wraps to next line', () {
      final terminal = Terminal(rows: 24, cols: 10);

      terminal.write('123456789\tX');

      // Tab at position 9 should wrap to next line
      expect(terminal.buffer.getCell(0, 1).char, 'X');
    });

    test('complex scenario with multiple control characters', () {
      final terminal = Terminal(rows: 5, cols: 20);

      terminal.write('Hello\tWorld\n');
      terminal.write('Line 2\n');
      terminal.write('Overwrite\rXXX');

      // Line 0: "Hello   World       " (tab at position 5 moves to 8)
      expect(terminal.buffer.getCell(0, 0).char, 'H');
      expect(terminal.buffer.getCell(8, 0).char, 'W');

      // Line 1: "Line 2              "
      expect(terminal.buffer.getCell(0, 1).char, 'L');

      // Line 2: "XXXrwrite           " (carriage return overwrites start)
      expect(terminal.buffer.getCell(0, 2).char, 'X');
      expect(terminal.buffer.getCell(1, 2).char, 'X');
      expect(terminal.buffer.getCell(2, 2).char, 'X');
      expect(terminal.buffer.getCell(3, 2).char, 'r');
    });

    test('writing empty string does nothing', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('');

      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 0);
    });

    test('multiple newlines', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('A\n\n\nB');

      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.buffer.getCell(0, 3).char, 'B');
      expect(terminal.cursor.y, 3);
    });
  });
}
