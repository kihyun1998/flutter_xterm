import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/flutter_xterm.dart';

void main() {
  group('Phase 1 Integration Tests', () {
    test('basic terminal operations', () {
      final terminal = Terminal(rows: 24, cols: 80);

      terminal.write('Hello, World!\n');
      terminal.write('Line 2\n');
      terminal.write('Tab\there');

      // Verify first line
      expect(terminal.buffer.getCell(0, 0).char, 'H');
      expect(terminal.buffer.getCell(6, 0).char, ' ');
      expect(terminal.buffer.getCell(7, 0).char, 'W');

      // Verify second line
      expect(terminal.buffer.getCell(0, 1).char, 'L');
      expect(terminal.buffer.getCell(5, 1).char, '2');

      // Verify third line with tab
      expect(terminal.buffer.getCell(0, 2).char, 'T');
      expect(terminal.buffer.getCell(8, 2).char, 'h');
    });

    test('buffer content as string', () {
      final terminal = Terminal(rows: 3, cols: 10);

      terminal.write('Hello\n');
      terminal.write('World\n');
      terminal.write('Test');

      final content = terminal.buffer.toString();
      final lines = content.split('\n');

      expect(lines[0].substring(0, 5), 'Hello');
      expect(lines[1].substring(0, 5), 'World');
      expect(lines[2].substring(0, 4), 'Test');
    });

    test('scrolling behavior with long output', () {
      final terminal = Terminal(rows: 5, cols: 10);

      for (int i = 0; i < 10; i++) {
        terminal.write('Line $i\n');
      }

      // After writing 10 lines to a 5-row terminal,
      // only the last 5 lines should be visible (Lines 5-9)
      // Each line starts with "Line " so position 5 has the number
      expect(terminal.buffer.getCell(5, 0).char, '6');
      expect(terminal.buffer.getCell(5, 1).char, '7');
      expect(terminal.buffer.getCell(5, 2).char, '8');
      expect(terminal.buffer.getCell(5, 3).char, '9');
      expect(terminal.buffer.getCell(5, 4).isEmpty, true); // Cursor line is empty
    });

    test('terminal resize preserves content', () {
      final terminal = Terminal(rows: 10, cols: 20);

      terminal.write('Test content\n');
      terminal.write('Line 2');

      // Resize to larger
      terminal.resize(20, 40);

      expect(terminal.rows, 20);
      expect(terminal.cols, 40);
      expect(terminal.buffer.getCell(0, 0).char, 'T');
      expect(terminal.buffer.getCell(0, 1).char, 'L');
    });

    test('clear and reset operations', () {
      final terminal = Terminal(rows: 10, cols: 20);

      terminal.write('Some text');
      terminal.clear();

      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 0);
      expect(terminal.buffer.getCell(0, 0).isEmpty, true);

      terminal.write('New text');
      terminal.reset();

      expect(terminal.buffer.getCell(0, 0).isEmpty, true);
    });

    test('styled text output', () {
      final terminal = Terminal(rows: 10, cols: 40);

      // Write normal text
      terminal.write('Normal ');

      // Write bold text
      terminal.setStyle(const TerminalCell(isBold: true));
      terminal.write('Bold ');

      // Write italic text
      terminal.setStyle(const TerminalCell(isItalic: true));
      terminal.write('Italic');

      // Reset and write normal
      terminal.resetStyle();
      terminal.write(' Normal');

      expect(terminal.buffer.getCell(0, 0).isBold, false);
      expect(terminal.buffer.getCell(7, 0).isBold, true);
      expect(terminal.buffer.getCell(12, 0).isItalic, true);
      expect(terminal.buffer.getCell(19, 0).isBold, false);
      expect(terminal.buffer.getCell(19, 0).isItalic, false);
    });

    test('complex multi-line scenario', () {
      final terminal = Terminal(rows: 5, cols: 30);

      terminal.write('#!/bin/bash\n');
      terminal.write('echo "Hello World"\n');
      terminal.write('cd /tmp\n');
      terminal.write('ls -la');

      // Verify the script-like output
      expect(terminal.buffer.getCell(0, 0).char, '#');
      expect(terminal.buffer.getCell(1, 0).char, '!');

      expect(terminal.buffer.getCell(0, 1).char, 'e');
      expect(terminal.buffer.getCell(1, 1).char, 'c');

      expect(terminal.buffer.getCell(0, 2).char, 'c');
      expect(terminal.buffer.getCell(1, 2).char, 'd');

      expect(terminal.buffer.getCell(0, 3).char, 'l');
      expect(terminal.buffer.getCell(1, 3).char, 's');
    });

    test('cursor positioning after various operations', () {
      final terminal = Terminal(rows: 10, cols: 20);

      terminal.write('ABC');
      expect(terminal.cursor.x, 3);
      expect(terminal.cursor.y, 0);

      terminal.write('\n');
      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 1);

      terminal.write('12345\t');
      expect(terminal.cursor.x, 8);
      expect(terminal.cursor.y, 1);

      terminal.write('X\r');
      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 1);

      terminal.write('Y\b');
      expect(terminal.cursor.x, 0);
      expect(terminal.cursor.y, 1);
    });

    test('full buffer filling and scrolling', () {
      final terminal = Terminal(rows: 3, cols: 5);

      // Fill entire buffer
      terminal.write('AAAAA'); // Row 0, cursor wraps to row 1
      terminal.write('BBBBB'); // Row 1, cursor wraps to row 2
      terminal.write('CCCCC'); // Row 2, cursor wraps to row 3 (scrolls!)

      // After 3rd write, scroll happens
      expect(terminal.buffer.getCell(0, 0).char, 'B');
      expect(terminal.buffer.getCell(0, 1).char, 'C');
      expect(terminal.buffer.getCell(0, 2).isEmpty, true);

      // Write more, causing another scroll
      terminal.write('DDDDD');

      expect(terminal.buffer.getCell(0, 0).char, 'C');
      expect(terminal.buffer.getCell(0, 1).char, 'D');
      expect(terminal.buffer.getCell(0, 2).isEmpty, true);
    });

    test('edge cases - minimal terminal', () {
      final terminal = Terminal(rows: 2, cols: 2);

      expect(terminal.rows, 2);
      expect(terminal.cols, 2);

      terminal.write('XY');
      expect(terminal.buffer.getCell(0, 0).char, 'X');
      expect(terminal.buffer.getCell(1, 0).char, 'Y');

      // Writing more wraps and scrolls
      terminal.write('AB');
      expect(terminal.buffer.getCell(0, 0).char, 'A');
      expect(terminal.buffer.getCell(1, 0).char, 'B');
      expect(terminal.buffer.getCell(0, 1).isEmpty, true);
    });
  });
}
