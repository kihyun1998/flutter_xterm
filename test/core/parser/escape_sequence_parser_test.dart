import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/flutter_xterm.dart';

void main() {
  group('EscapeSequenceParser', () {
    late EscapeSequenceParser parser;

    setUp(() {
      parser = EscapeSequenceParser();
    });

    test('parses plain text', () {
      final commands = parser.parse('Hello');

      expect(commands.length, 5);
      expect(commands[0], isA<PrintCommand>());
      expect((commands[0] as PrintCommand).char, 'H');
      expect((commands[1] as PrintCommand).char, 'e');
    });

    test('parses control characters', () {
      final commands = parser.parse('A\nB\rC\tD');

      expect(commands.length, 7);
      expect(commands[0], isA<PrintCommand>());
      expect((commands[0] as PrintCommand).char, 'A');
      expect(commands[1], isA<ControlCommand>());
      expect((commands[1] as ControlCommand).char, '\n');
      expect(commands[2], isA<PrintCommand>());
      expect((commands[2] as PrintCommand).char, 'B');
    });

    test('parses simple CSI sequence - SGR red', () {
      final commands = parser.parse('\x1b[31m');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'm');
      expect(csi.params, [31]);
    });

    test('parses CSI sequence with multiple parameters', () {
      final commands = parser.parse('\x1b[1;32m');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'm');
      expect(csi.params, [1, 32]);
    });

    test('parses cursor position command', () {
      final commands = parser.parse('\x1b[10;20H');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'H');
      expect(csi.params, [10, 20]);
    });

    test('parses CSI sequence with no parameters', () {
      final commands = parser.parse('\x1b[H');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'H');
      expect(csi.params.isEmpty, true);
    });

    test('parses erase display command', () {
      final commands = parser.parse('\x1b[2J');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'J');
      expect(csi.params, [2]);
    });

    test('parses DEC private mode CSI sequence', () {
      final commands = parser.parse('\x1b[?1049h');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.finalByte, 'h');
      expect(csi.params, [1049]);
      expect(csi.intermediates, '?');
    });

    test('parses OSC title sequence', () {
      final commands = parser.parse('\x1b]2;My Title\x07');

      expect(commands.length, 1);
      expect(commands[0], isA<OscCommand>());
      final osc = commands[0] as OscCommand;
      expect(osc.command, 2);
      expect(osc.data, 'My Title');
    });

    test('parses OSC sequence with ST terminator', () {
      final commands = parser.parse('\x1b]0;Icon+Title\x1b\\');

      expect(commands.length, 1);
      expect(commands[0], isA<OscCommand>());
      final osc = commands[0] as OscCommand;
      expect(osc.command, 0);
      expect(osc.data, 'Icon+Title');
    });

    test('parses mixed text and escape sequences', () {
      final commands = parser.parse('Hello\x1b[31mRed\x1b[0m');

      expect(commands.length, 10); // 5 + CSI + 3 + CSI

      expect(commands[0], isA<PrintCommand>());
      expect((commands[0] as PrintCommand).char, 'H');

      expect(commands[5], isA<CsiCommand>());
      final csi1 = commands[5] as CsiCommand;
      expect(csi1.params, [31]);

      expect(commands[6], isA<PrintCommand>());
      expect((commands[6] as PrintCommand).char, 'R');

      expect(commands[9], isA<CsiCommand>());
      final csi2 = commands[9] as CsiCommand;
      expect(csi2.params, [0]);
    });

    test('handles empty parameters in CSI', () {
      final commands = parser.parse('\x1b[;5;m');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.params, [0, 5, 0]);
    });

    test('maintains state across multiple parse calls', () {
      parser.parse('\x1b');
      final commands = parser.parse('[31m');

      expect(commands.length, 1);
      expect(commands[0], isA<CsiCommand>());
      final csi = commands[0] as CsiCommand;
      expect(csi.params, [31]);
    });

    test('reset clears parser state', () {
      parser.parse('\x1b');
      parser.reset();
      final commands = parser.parse('[31m');

      // After reset, should parse '[31m' as plain text
      expect(commands.length, 5);
      expect(commands[0], isA<PrintCommand>());
    });
  });
}
