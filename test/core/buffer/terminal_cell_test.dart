import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/src/core/buffer/terminal_cell.dart';

void main() {
  group('TerminalCell', () {
    test('creates default cell with space character', () {
      const cell = TerminalCell();

      expect(cell.char, ' ');
      expect(cell.foregroundColor, isNull);
      expect(cell.backgroundColor, isNull);
      expect(cell.isBold, false);
      expect(cell.isItalic, false);
      expect(cell.isUnderline, false);
    });

    test('creates cell with custom properties', () {
      const cell = TerminalCell(
        char: 'A',
        foregroundColor: Colors.red,
        backgroundColor: Colors.blue,
        isBold: true,
        isItalic: true,
        isUnderline: true,
      );

      expect(cell.char, 'A');
      expect(cell.foregroundColor, Colors.red);
      expect(cell.backgroundColor, Colors.blue);
      expect(cell.isBold, true);
      expect(cell.isItalic, true);
      expect(cell.isUnderline, true);
    });

    test('creates empty cell via factory constructor', () {
      final cell = TerminalCell.empty();

      expect(cell.char, ' ');
      expect(cell.isEmpty, true);
    });

    test('isEmpty returns true for empty cell', () {
      const cell = TerminalCell();
      expect(cell.isEmpty, true);
    });

    test('isEmpty returns false when char is not space', () {
      const cell = TerminalCell(char: 'A');
      expect(cell.isEmpty, false);
    });

    test('isEmpty returns false when cell has styling', () {
      const cell1 = TerminalCell(foregroundColor: Colors.red);
      const cell2 = TerminalCell(backgroundColor: Colors.blue);
      const cell3 = TerminalCell(isBold: true);
      const cell4 = TerminalCell(isItalic: true);
      const cell5 = TerminalCell(isUnderline: true);

      expect(cell1.isEmpty, false);
      expect(cell2.isEmpty, false);
      expect(cell3.isEmpty, false);
      expect(cell4.isEmpty, false);
      expect(cell5.isEmpty, false);
    });

    test('copyWith creates new cell with modified properties', () {
      const original = TerminalCell(char: 'A', isBold: true);
      final modified = original.copyWith(char: 'B');

      expect(modified.char, 'B');
      expect(modified.isBold, true);
      expect(original.char, 'A'); // original unchanged
    });

    test('copyWith with no arguments creates identical cell', () {
      const original = TerminalCell(char: 'A', isBold: true);
      final copy = original.copyWith();

      expect(copy.char, original.char);
      expect(copy.isBold, original.isBold);
    });

    test('equality works correctly', () {
      const cell1 = TerminalCell(char: 'A', isBold: true);
      const cell2 = TerminalCell(char: 'A', isBold: true);
      const cell3 = TerminalCell(char: 'B', isBold: true);

      expect(cell1, equals(cell2));
      expect(cell1, isNot(equals(cell3)));
    });

    test('hashCode is consistent with equality', () {
      const cell1 = TerminalCell(char: 'A', isBold: true);
      const cell2 = TerminalCell(char: 'A', isBold: true);

      expect(cell1.hashCode, equals(cell2.hashCode));
    });

    test('toString provides useful representation', () {
      const cell = TerminalCell(
        char: 'A',
        foregroundColor: Colors.red,
        isBold: true,
      );

      final str = cell.toString();
      expect(str, contains('A'));
      expect(str, contains('bold: true'));
    });
  });
}
