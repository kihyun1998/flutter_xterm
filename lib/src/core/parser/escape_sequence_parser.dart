import 'parser_state.dart';
import 'ansi_command.dart';

/// ANSI escape sequence parser based on a state machine.
///
/// This parser follows the VT100/xterm standard for parsing escape sequences.
/// Reference: https://vt100.net/emu/dec_ansi_parser
///
/// The parser converts a string of text (including escape sequences) into
/// a list of [AnsiCommand] objects that can be executed by the terminal.
///
/// Example:
/// ```dart
/// final parser = EscapeSequenceParser();
/// final commands = parser.parse('\x1b[31mRed text\x1b[0m');
/// // Returns: [
/// //   CsiCommand(finalByte: 'm', params: [31]),
/// //   PrintCommand('R'),
/// //   PrintCommand('e'),
/// //   PrintCommand('d'),
/// //   ...
/// // ]
/// ```
class EscapeSequenceParser {
  /// Current parser state.
  ParserState _state = ParserState.ground;

  /// CSI parameter accumulation.
  final List<int> _params = [];
  String _currentParam = '';
  String _intermediates = '';

  /// OSC data accumulation.
  String _oscData = '';
  int _oscCommand = 0;
  bool _oscCommandParsed = false;

  /// Parse a string and return a list of ANSI commands.
  ///
  /// The parser maintains state across calls, so you can feed it
  /// partial strings and it will continue parsing from where it left off.
  List<AnsiCommand> parse(String text) {
    final commands = <AnsiCommand>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);

      switch (_state) {
        case ParserState.ground:
          _handleGround(char, code, commands);
          break;

        case ParserState.escape:
          _handleEscape(char, code, commands);
          break;

        case ParserState.escapeIntermediate:
          _handleEscapeIntermediate(char, code, commands);
          break;

        case ParserState.csiEntry:
          _handleCsiEntry(char, code, commands);
          break;

        case ParserState.csiParam:
          _handleCsiParam(char, code, commands);
          break;

        case ParserState.csiIntermediate:
          _handleCsiIntermediate(char, code, commands);
          break;

        case ParserState.oscString:
          _handleOscString(char, code, commands);
          break;

        case ParserState.dcsEntry:
        case ParserState.dcsParam:
        case ParserState.dcsPassthrough:
          _handleDcs(char, code, commands);
          break;
      }
    }

    return commands;
  }

  /// Reset the parser to the initial state.
  void reset() {
    _state = ParserState.ground;
    _resetCsiState();
    _resetOscState();
  }

  // === State Handlers ===

  void _handleGround(String char, int code, List<AnsiCommand> commands) {
    if (code == 0x1B) {
      // ESC
      _state = ParserState.escape;
    } else if (code < 0x20) {
      // Control characters (0x00-0x1F)
      commands.add(ControlCommand(char));
    } else if (code == 0x7F) {
      // DEL - ignore
    } else {
      // Printable characters
      commands.add(PrintCommand(char));
    }
  }

  void _handleEscape(String char, int code, List<AnsiCommand> commands) {
    switch (char) {
      case '[':
        // CSI - Control Sequence Introducer
        _state = ParserState.csiEntry;
        _resetCsiState();
        break;

      case ']':
        // OSC - Operating System Command
        _state = ParserState.oscString;
        _resetOscState();
        break;

      case 'P':
        // DCS - Device Control String
        _state = ParserState.dcsEntry;
        break;

      case '\\':
        // ST - String Terminator (used with OSC)
        _state = ParserState.ground;
        break;

      case 'D':
        // IND - Index (move cursor down, scroll if needed)
        // Emit a control command for now
        _state = ParserState.ground;
        break;

      case 'M':
        // RI - Reverse Index (move cursor up, scroll if needed)
        _state = ParserState.ground;
        break;

      case 'E':
        // NEL - Next Line
        _state = ParserState.ground;
        break;

      default:
        if (code >= 0x20 && code <= 0x2F) {
          // Intermediate bytes
          _state = ParserState.escapeIntermediate;
        } else {
          // Unknown escape sequence - return to ground
          _state = ParserState.ground;
        }
    }
  }

  void _handleEscapeIntermediate(
      String char, int code, List<AnsiCommand> commands) {
    if (code >= 0x30 && code <= 0x7E) {
      // Final byte - end of escape sequence
      _state = ParserState.ground;
    } else if (code >= 0x20 && code <= 0x2F) {
      // More intermediate bytes - stay in this state
    } else {
      // Invalid - return to ground
      _state = ParserState.ground;
    }
  }

  void _handleCsiEntry(String char, int code, List<AnsiCommand> commands) {
    if (code >= 0x30 && code <= 0x39) {
      // Digit - start parameter
      _currentParam = char;
      _state = ParserState.csiParam;
    } else if (char == ';') {
      // Empty parameter
      _params.add(0);
      _state = ParserState.csiParam;
    } else if (code >= 0x3C && code <= 0x3F) {
      // Private parameter bytes (?, <, =, >)
      _intermediates += char;
      _state = ParserState.csiParam;
    } else if (code >= 0x20 && code <= 0x2F) {
      // Intermediate bytes
      _intermediates += char;
      _state = ParserState.csiIntermediate;
    } else if (code >= 0x40 && code <= 0x7E) {
      // Final byte - emit command
      _emitCsiCommand(char, commands);
      _state = ParserState.ground;
    } else {
      // Invalid - return to ground
      _state = ParserState.ground;
    }
  }

  void _handleCsiParam(String char, int code, List<AnsiCommand> commands) {
    if (code >= 0x30 && code <= 0x39) {
      // Digit - accumulate parameter
      _currentParam += char;
    } else if (char == ';') {
      // Parameter separator
      _finishCurrentParam();
      // Stay in csiParam state for next parameter
    } else if (code >= 0x20 && code <= 0x2F) {
      // Intermediate bytes
      _finishCurrentParam();
      _intermediates += char;
      _state = ParserState.csiIntermediate;
    } else if (code >= 0x40 && code <= 0x7E) {
      // Final byte - emit command
      _finishCurrentParam();
      _emitCsiCommand(char, commands);
      _state = ParserState.ground;
    } else if (code >= 0x3C && code <= 0x3F) {
      // Private parameter bytes
      _intermediates += char;
    } else {
      // Invalid - return to ground
      _state = ParserState.ground;
    }
  }

  void _handleCsiIntermediate(
      String char, int code, List<AnsiCommand> commands) {
    if (code >= 0x20 && code <= 0x2F) {
      // More intermediate bytes
      _intermediates += char;
    } else if (code >= 0x40 && code <= 0x7E) {
      // Final byte - emit command
      _emitCsiCommand(char, commands);
      _state = ParserState.ground;
    } else {
      // Invalid - return to ground
      _state = ParserState.ground;
    }
  }

  void _handleOscString(String char, int code, List<AnsiCommand> commands) {
    if (code == 0x07) {
      // BEL - End of OSC sequence
      _emitOscCommand(commands);
      _state = ParserState.ground;
    } else if (code == 0x1B) {
      // ESC - might be followed by \ for ST
      // For simplicity, emit OSC here and go to escape state
      _emitOscCommand(commands);
      _state = ParserState.escape;
    } else if (!_oscCommandParsed && char == ';') {
      // Separator between command number and data
      _oscCommand = int.tryParse(_oscData) ?? 0;
      _oscData = '';
      _oscCommandParsed = true;
    } else {
      // Accumulate OSC data
      _oscData += char;
    }
  }

  void _handleDcs(String char, int code, List<AnsiCommand> commands) {
    // DCS sequences are not commonly used in basic terminal emulation
    // For now, we'll ignore them and return to ground on ST or BEL
    if (code == 0x1B) {
      _state = ParserState.escape;
    } else if (code == 0x07) {
      _state = ParserState.ground;
    }
    // Otherwise stay in DCS state and ignore characters
  }

  // === Helper Methods ===

  void _finishCurrentParam() {
    if (_currentParam.isNotEmpty) {
      _params.add(int.tryParse(_currentParam) ?? 0);
      _currentParam = '';
    } else {
      // Empty parameter defaults to 0
      _params.add(0);
    }
  }

  void _emitCsiCommand(String finalByte, List<AnsiCommand> commands) {
    commands.add(CsiCommand(
      finalByte: finalByte,
      params: List.from(_params),
      intermediates: _intermediates,
    ));
    _resetCsiState();
  }

  void _emitOscCommand(List<AnsiCommand> commands) {
    if (!_oscCommandParsed) {
      // If no separator was found, try to parse the whole string as command
      final parts = _oscData.split(';');
      if (parts.length >= 2) {
        _oscCommand = int.tryParse(parts[0]) ?? 0;
        _oscData = parts.sublist(1).join(';');
      }
    }

    commands.add(OscCommand(
      command: _oscCommand,
      data: _oscData,
    ));
    _resetOscState();
  }

  void _resetCsiState() {
    _params.clear();
    _currentParam = '';
    _intermediates = '';
  }

  void _resetOscState() {
    _oscData = '';
    _oscCommand = 0;
    _oscCommandParsed = false;
  }
}
