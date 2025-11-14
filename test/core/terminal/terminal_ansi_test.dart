import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/flutter_xterm.dart';

void main() {
  group('Terminal - ANSI Escape Sequences', () {
    late Terminal terminal;

    setUp(() {
      terminal = Terminal(rows: 24, cols: 80);
    });

    group('SGR - Colors and Styles', () {
      test('applies red foreground color', () {
        terminal.write('\x1b[31mRed\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.char, 'R');
        expect(cell.foregroundColor, isNotNull);
        expect(cell.foregroundColor, AnsiColors.red);
      });

      test('applies bright green foreground color', () {
        terminal.write('\x1b[92mGreen\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.foregroundColor, AnsiColors.brightGreen);
      });

      test('applies background color', () {
        terminal.write('\x1b[44mBlue BG\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.backgroundColor, AnsiColors.blue);
      });

      test('applies bold style', () {
        terminal.write('\x1b[1mBold\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.isBold, true);
      });

      test('applies italic style', () {
        terminal.write('\x1b[3mItalic\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.isItalic, true);
      });

      test('applies underline style', () {
        terminal.write('\x1b[4mUnderline\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.isUnderline, true);
      });

      test('resets all styles with SGR 0', () {
        terminal.write('\x1b[1;31mBold Red\x1b[0mNormal');

        final boldCell = terminal.buffer.getCell(0, 0);
        expect(boldCell.isBold, true);
        expect(boldCell.foregroundColor, AnsiColors.red);

        final normalCell = terminal.buffer.getCell(8, 0);
        expect(normalCell.isBold, false);
        expect(normalCell.foregroundColor, null);
      });

      test('applies multiple styles at once', () {
        terminal.write('\x1b[1;3;4;31mMultiple\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.isBold, true);
        expect(cell.isItalic, true);
        expect(cell.isUnderline, true);
        expect(cell.foregroundColor, AnsiColors.red);
      });

      test('handles 256-color foreground', () {
        terminal.write('\x1b[38;5;196mRed256\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.foregroundColor, isNotNull);
        // Color 196 should be a bright red in the 256-color palette
      });

      test('handles RGB foreground color', () {
        terminal.write('\x1b[38;2;255;0;0mRGB\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.foregroundColor, const Color(0xFFFF0000));
      });

      test('handles RGB background color', () {
        terminal.write('\x1b[48;2;0;255;0mRGB BG\x1b[0m');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.backgroundColor, const Color(0xFF00FF00));
      });
    });

    group('Cursor Movement', () {
      test('moves cursor up (CUU)', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[3A');

        expect(terminal.cursor.y, 7);
        expect(terminal.cursor.x, 10);
      });

      test('moves cursor down (CUD)', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[5B');

        expect(terminal.cursor.y, 15);
      });

      test('moves cursor right (CUF)', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[7C');

        expect(terminal.cursor.x, 17);
      });

      test('moves cursor left (CUB)', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[4D');

        expect(terminal.cursor.x, 6);
      });

      test('sets cursor position (CUP)', () {
        terminal.write('\x1b[5;10H');

        expect(terminal.cursor.y, 4); // 0-indexed
        expect(terminal.cursor.x, 9); // 0-indexed
      });

      test('moves cursor to column (CHA)', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[20G');

        expect(terminal.cursor.x, 19); // 0-indexed
        expect(terminal.cursor.y, 10);
      });

      test('CUP with no parameters moves to home', () {
        terminal.setCursorPosition(10, 10);
        terminal.write('\x1b[H');

        expect(terminal.cursor.x, 0);
        expect(terminal.cursor.y, 0);
      });
    });

    group('Screen Manipulation', () {
      test('clears screen (ED 2)', () {
        terminal.write('Hello World');
        terminal.write('\x1b[H\x1b[2J');

        // Check that the first cell is now empty
        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.char, ' ');
      });

      test('clears from cursor to end of screen (ED 0)', () {
        terminal.write('Line1\nLine2\nLine3');
        terminal.setCursorPosition(3, 1);
        terminal.write('\x1b[J');

        // First line should be intact
        final cell00 = terminal.buffer.getCell(0, 0);
        expect(cell00.char, 'L');

        // Position after cursor on line 1 should be clear
        final cell31 = terminal.buffer.getCell(3, 1);
        expect(cell31.char, ' ');

        // Line 2 should be clear
        final cell02 = terminal.buffer.getCell(0, 2);
        expect(cell02.char, ' ');
      });

      test('clears line (EL 2)', () {
        terminal.write('Hello World');
        terminal.setCursorPosition(0, 0);
        terminal.write('\x1b[2K');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.char, ' ');
      });

      test('clears from cursor to end of line (EL 0)', () {
        terminal.write('Hello World');
        terminal.setCursorPosition(5, 0);
        terminal.write('\x1b[K');

        final cell4 = terminal.buffer.getCell(4, 0);
        expect(cell4.char, 'o');

        final cell5 = terminal.buffer.getCell(5, 0);
        expect(cell5.char, ' ');
      });
    });

    group('OSC Sequences', () {
      test('sets terminal title', () {
        terminal.write('\x1b]2;My Terminal\x07');

        expect(terminal.title, 'My Terminal');
      });

      test('sets icon name and title', () {
        terminal.write('\x1b]0;Title\x07');

        expect(terminal.title, 'Title');
        expect(terminal.iconName, 'Title');
      });
    });

    group('Mode Setting', () {
      test('shows and hides cursor', () {
        terminal.write('\x1b[?25l'); // Hide cursor
        expect(terminal.cursor.isVisible, false);

        terminal.write('\x1b[?25h'); // Show cursor
        expect(terminal.cursor.isVisible, true);
      });

      test('switches to alternate buffer', () {
        terminal.write('Main buffer text');
        final mainCell = terminal.buffer.getCell(0, 0);
        expect(mainCell.char, 'M');

        terminal.write('\x1b[?1049h'); // Enter alternate buffer
        final altCell = terminal.buffer.getCell(0, 0);
        expect(altCell.char, ' '); // Should be empty

        terminal.write('Alt buffer text');
        final altTextCell = terminal.buffer.getCell(0, 0);
        expect(altTextCell.char, 'A');

        terminal.write('\x1b[?1049l'); // Exit alternate buffer
        final restoredCell = terminal.buffer.getCell(0, 0);
        expect(restoredCell.char, 'M'); // Main buffer restored
      });
    });

    group('Complex Scenarios', () {
      test('handles colored text with mixed content', () {
        terminal.write('Normal ');
        terminal.write('\x1b[31mRed ');
        terminal.write('\x1b[32mGreen ');
        terminal.write('\x1b[0mNormal');

        final normal1 = terminal.buffer.getCell(0, 0);
        expect(normal1.foregroundColor, null);

        final red = terminal.buffer.getCell(7, 0);
        expect(red.foregroundColor, AnsiColors.red);

        final green = terminal.buffer.getCell(11, 0);
        expect(green.foregroundColor, AnsiColors.green);

        final normal2 = terminal.buffer.getCell(17, 0);
        expect(normal2.foregroundColor, null);
      });

      test('handles cursor movement with colored text', () {
        terminal.write('\x1b[31mRed');
        terminal.write('\x1b[H'); // Move to home
        terminal.write('\x1b[32mGreen');

        final cell = terminal.buffer.getCell(0, 0);
        expect(cell.char, 'G');
        expect(cell.foregroundColor, AnsiColors.green);
      });

      test('real-world ls --color output simulation', () {
        // Simulate: file.txt (normal) directory (blue) executable (green)
        terminal.write('file.txt  ');
        terminal.write('\x1b[34mdirectory\x1b[0m  ');
        terminal.write('\x1b[32mexecutable\x1b[0m');

        // Check file.txt is normal
        final file = terminal.buffer.getCell(0, 0);
        expect(file.char, 'f');
        expect(file.foregroundColor, null);

        // Check directory is blue
        final dir = terminal.buffer.getCell(10, 0);
        expect(dir.char, 'd');
        expect(dir.foregroundColor, AnsiColors.blue);

        // Check executable is green
        final exe = terminal.buffer.getCell(22, 0);
        expect(exe.char, 'e');
        expect(exe.foregroundColor, AnsiColors.green);
      });
    });
  });
}
