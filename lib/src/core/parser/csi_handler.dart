import '../terminal/terminal.dart';
import 'ansi_command.dart';
import 'sgr_handler.dart';

/// Handler for CSI (Control Sequence Introducer) commands.
///
/// CSI sequences start with ESC [ and end with a letter.
/// They are used for cursor movement, screen manipulation, and text styling.
///
/// Examples:
/// - ESC[H: Move cursor to home (1,1)
/// - ESC[2J: Clear screen
/// - ESC[31m: Set foreground color to red
/// - ESC[10;20H: Move cursor to row 10, column 20
class CsiHandler {
  /// Execute a CSI command on the terminal.
  static void execute(Terminal terminal, CsiCommand cmd) {
    final params = cmd.params;
    final finalByte = cmd.finalByte;
    final intermediates = cmd.intermediates;

    switch (finalByte) {
      // === Cursor Movement ===

      case 'A': // CUU - Cursor Up
        final n = _getParam(params, 0, 1);
        terminal.moveCursorUp(n);
        break;

      case 'B': // CUD - Cursor Down
        final n = _getParam(params, 0, 1);
        terminal.moveCursorDown(n);
        break;

      case 'C': // CUF - Cursor Forward (Right)
        final n = _getParam(params, 0, 1);
        terminal.moveCursorRight(n);
        break;

      case 'D': // CUB - Cursor Back (Left)
        final n = _getParam(params, 0, 1);
        terminal.moveCursorLeft(n);
        break;

      case 'E': // CNL - Cursor Next Line
        final n = _getParam(params, 0, 1);
        terminal.moveCursorDown(n);
        terminal.setCursorColumn(0);
        break;

      case 'F': // CPL - Cursor Previous Line
        final n = _getParam(params, 0, 1);
        terminal.moveCursorUp(n);
        terminal.setCursorColumn(0);
        break;

      case 'G': // CHA - Cursor Horizontal Absolute
        final col = _getParam(params, 0, 1);
        terminal.setCursorColumn(col - 1); // Convert to 0-indexed
        break;

      case 'H': // CUP - Cursor Position
      case 'f': // HVP - Horizontal Vertical Position (same as CUP)
        final row = _getParam(params, 0, 1);
        final col = _getParam(params, 1, 1);
        terminal.setCursorPosition(col - 1, row - 1); // Convert to 0-indexed
        break;

      case 'd': // VPA - Vertical Position Absolute
        final row = _getParam(params, 0, 1);
        terminal.setCursorRow(row - 1); // Convert to 0-indexed
        break;

      // === Screen Manipulation ===

      case 'J': // ED - Erase in Display
        final mode = _getParam(params, 0, 0);
        switch (mode) {
          case 0: // Erase from cursor to end of screen
            terminal.eraseDisplayBelow();
            break;
          case 1: // Erase from start of screen to cursor
            terminal.eraseDisplayAbove();
            break;
          case 2: // Erase entire screen
          case 3: // Erase entire screen + scrollback
            terminal.eraseDisplay();
            break;
        }
        break;

      case 'K': // EL - Erase in Line
        final mode = _getParam(params, 0, 0);
        switch (mode) {
          case 0: // Erase from cursor to end of line
            terminal.eraseLineRight();
            break;
          case 1: // Erase from start of line to cursor
            terminal.eraseLineLeft();
            break;
          case 2: // Erase entire line
            terminal.eraseLine();
            break;
        }
        break;

      case 'S': // SU - Scroll Up
        final n = _getParam(params, 0, 1);
        terminal.scrollUp(n);
        break;

      case 'T': // SD - Scroll Down
        final n = _getParam(params, 0, 1);
        terminal.scrollDown(n);
        break;

      case 'L': // IL - Insert Lines
        final n = _getParam(params, 0, 1);
        terminal.insertLines(n);
        break;

      case 'M': // DL - Delete Lines
        final n = _getParam(params, 0, 1);
        terminal.deleteLines(n);
        break;

      case '@': // ICH - Insert Characters
        final n = _getParam(params, 0, 1);
        terminal.insertChars(n);
        break;

      case 'P': // DCH - Delete Characters
        final n = _getParam(params, 0, 1);
        terminal.deleteChars(n);
        break;

      case 'X': // ECH - Erase Characters
        final n = _getParam(params, 0, 1);
        terminal.eraseChars(n);
        break;

      // === Text Styling ===

      case 'm': // SGR - Select Graphic Rendition
        final newStyle = SgrHandler.applyParams(
          terminal.getCurrentStyle(),
          params,
        );
        terminal.setStyle(newStyle);
        break;

      // === Mode Setting ===

      case 'h': // SM - Set Mode
        _handleSetMode(terminal, params, intermediates);
        break;

      case 'l': // RM - Reset Mode
        _handleResetMode(terminal, params, intermediates);
        break;

      // === Cursor Save/Restore ===

      case 's': // SCP - Save Cursor Position
        terminal.saveCursor();
        break;

      case 'u': // RCP - Restore Cursor Position
        terminal.restoreCursor();
        break;

      // === Other ===

      case 'r': // DECSTBM - Set Top and Bottom Margins (scrolling region)
        final top = _getParam(params, 0, 1);
        final bottom = _getParam(params, 1, terminal.rows);
        terminal.setScrollRegion(top - 1, bottom - 1); // Convert to 0-indexed
        break;

      // Unknown CSI sequence - ignore
      default:
        break;
    }
  }

  /// Handle Set Mode commands (CSI h and CSI ? h).
  static void _handleSetMode(
    Terminal terminal,
    List<int> params,
    String intermediates,
  ) {
    if (intermediates == '?') {
      // DEC Private Mode Set (DECSET)
      for (final param in params) {
        switch (param) {
          case 1: // DECCKM - Cursor Keys Mode
            terminal.setCursorKeysMode(true);
            break;
          case 25: // DECTCEM - Text Cursor Enable
            terminal.showCursor(true);
            break;
          case 1049: // Alternate screen buffer
            terminal.useAlternateBuffer(true);
            break;
          case 2004: // Bracketed paste mode
            terminal.setBracketedPasteMode(true);
            break;
          // Add more DEC private modes as needed
        }
      }
    } else {
      // Standard mode set
      for (final param in params) {
        switch (param) {
          case 4: // IRM - Insert/Replace Mode
            terminal.setInsertMode(true);
            break;
          case 20: // LNM - Line Feed/New Line Mode
            terminal.setNewLineMode(true);
            break;
          // Add more standard modes as needed
        }
      }
    }
  }

  /// Handle Reset Mode commands (CSI l and CSI ? l).
  static void _handleResetMode(
    Terminal terminal,
    List<int> params,
    String intermediates,
  ) {
    if (intermediates == '?') {
      // DEC Private Mode Reset (DECRST)
      for (final param in params) {
        switch (param) {
          case 1: // DECCKM - Cursor Keys Mode
            terminal.setCursorKeysMode(false);
            break;
          case 25: // DECTCEM - Text Cursor Enable
            terminal.showCursor(false);
            break;
          case 1049: // Alternate screen buffer
            terminal.useAlternateBuffer(false);
            break;
          case 2004: // Bracketed paste mode
            terminal.setBracketedPasteMode(false);
            break;
          // Add more DEC private modes as needed
        }
      }
    } else {
      // Standard mode reset
      for (final param in params) {
        switch (param) {
          case 4: // IRM - Insert/Replace Mode
            terminal.setInsertMode(false);
            break;
          case 20: // LNM - Line Feed/New Line Mode
            terminal.setNewLineMode(false);
            break;
          // Add more standard modes as needed
        }
      }
    }
  }

  /// Get parameter at index with default value.
  static int _getParam(List<int> params, int index, int defaultValue) {
    if (index >= params.length) return defaultValue;
    final value = params[index];
    return value == 0 ? defaultValue : value;
  }
}
