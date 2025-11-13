/// Base class for all ANSI escape sequence commands.
///
/// After parsing, the parser produces a list of [AnsiCommand] objects
/// that the terminal can execute.
abstract class AnsiCommand {
  const AnsiCommand();
}

/// Command to print a single character to the terminal.
class PrintCommand extends AnsiCommand {
  /// The character to print.
  final String char;

  const PrintCommand(this.char);

  @override
  String toString() => 'PrintCommand("$char")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintCommand &&
          runtimeType == other.runtimeType &&
          char == other.char;

  @override
  int get hashCode => char.hashCode;
}

/// Command for control characters (\n, \r, \t, \b, etc.).
class ControlCommand extends AnsiCommand {
  /// The control character.
  final String char;

  const ControlCommand(this.char);

  @override
  String toString() {
    final escaped = char.replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll('\b', '\\b');
    return 'ControlCommand("$escaped")';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControlCommand &&
          runtimeType == other.runtimeType &&
          char == other.char;

  @override
  int get hashCode => char.hashCode;
}

/// CSI (Control Sequence Introducer) command.
///
/// CSI sequences start with ESC [ and end with a final byte (e.g., 'm', 'H', 'J').
/// They can have parameters (semicolon-separated integers) and intermediate bytes.
///
/// Examples:
/// - ESC[31m → CsiCommand(finalByte: 'm', params: [31])
/// - ESC[2J → CsiCommand(finalByte: 'J', params: [2])
/// - ESC[10;20H → CsiCommand(finalByte: 'H', params: [10, 20])
class CsiCommand extends AnsiCommand {
  /// The final byte that identifies the command (e.g., 'm', 'H', 'J').
  final String finalByte;

  /// Parameter list (semicolon-separated integers from the sequence).
  final List<int> params;

  /// Intermediate bytes (rarely used, e.g., for private sequences).
  final String intermediates;

  const CsiCommand({
    required this.finalByte,
    this.params = const [],
    this.intermediates = '',
  });

  @override
  String toString() {
    final paramsStr = params.isEmpty ? '' : params.join(';');
    return 'CsiCommand(finalByte: "$finalByte", params: [$paramsStr], intermediates: "$intermediates")';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CsiCommand &&
          runtimeType == other.runtimeType &&
          finalByte == other.finalByte &&
          _listEquals(params, other.params) &&
          intermediates == other.intermediates;

  @override
  int get hashCode =>
      finalByte.hashCode ^ params.hashCode ^ intermediates.hashCode;

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// OSC (Operating System Command) command.
///
/// OSC sequences start with ESC ] and are terminated by BEL (0x07) or ST (ESC \).
/// They are used for terminal-specific operations like setting the window title.
///
/// Examples:
/// - ESC]0;My Title\x07 → OscCommand(command: 0, data: "My Title")
/// - ESC]2;Window Title\x07 → OscCommand(command: 2, data: "Window Title")
class OscCommand extends AnsiCommand {
  /// The OSC command number (e.g., 0 for icon+title, 2 for title).
  final int command;

  /// The data string for the command.
  final String data;

  const OscCommand({
    required this.command,
    required this.data,
  });

  @override
  String toString() => 'OscCommand(command: $command, data: "$data")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OscCommand &&
          runtimeType == other.runtimeType &&
          command == other.command &&
          data == other.data;

  @override
  int get hashCode => command.hashCode ^ data.hashCode;
}
