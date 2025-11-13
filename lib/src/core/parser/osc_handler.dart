import '../terminal/terminal.dart';
import 'ansi_command.dart';

/// Handler for OSC (Operating System Command) sequences.
///
/// OSC sequences start with ESC ] and are terminated by BEL (0x07) or ST (ESC \).
/// They are used for terminal-specific operations like setting the window title.
///
/// Common OSC commands:
/// - OSC 0: Set icon name and window title
/// - OSC 1: Set icon name
/// - OSC 2: Set window title
/// - OSC 4: Set/query color palette
/// - OSC 10: Set foreground color
/// - OSC 11: Set background color
/// - OSC 52: Clipboard operations
///
/// Examples:
/// - ESC]0;My Title\x07: Set window title to "My Title"
/// - ESC]2;Terminal\x07: Set window title to "Terminal"
class OscHandler {
  /// Execute an OSC command on the terminal.
  static void execute(Terminal terminal, OscCommand cmd) {
    switch (cmd.command) {
      case 0: // Set icon name and window title
        terminal.setTitle(cmd.data);
        terminal.setIconName(cmd.data);
        break;

      case 1: // Set icon name
        terminal.setIconName(cmd.data);
        break;

      case 2: // Set window title
        terminal.setTitle(cmd.data);
        break;

      case 4: // Set/query color palette
        _handleColorPalette(terminal, cmd.data);
        break;

      case 10: // Set foreground color
        _handleSetColor(terminal, cmd.data, isForeground: true);
        break;

      case 11: // Set background color
        _handleSetColor(terminal, cmd.data, isForeground: false);
        break;

      case 52: // Clipboard operations
        _handleClipboard(terminal, cmd.data);
        break;

      // Unknown OSC command - ignore
      default:
        break;
    }
  }

  /// Handle OSC 4 - Color palette manipulation.
  ///
  /// Format: OSC 4 ; index ; color spec
  /// Example: OSC 4;1;rgb:ff/00/00 (set color 1 to red)
  static void _handleColorPalette(Terminal terminal, String data) {
    // Parse: index;colorspec or index;colorspec;index;colorspec...
    final parts = data.split(';');

    for (int i = 0; i + 1 < parts.length; i += 2) {
      final index = int.tryParse(parts[i]);
      final colorSpec = parts[i + 1];

      if (index != null && index >= 0 && index < 256) {
        final color = _parseColorSpec(colorSpec);
        if (color != null) {
          terminal.setPaletteColor(index, color);
        }
      }
    }
  }

  /// Handle OSC 10/11 - Set foreground/background color.
  ///
  /// Format: OSC 10 ; color spec
  static void _handleSetColor(
    Terminal terminal,
    String data, {
    required bool isForeground,
  }) {
    final color = _parseColorSpec(data);
    if (color != null) {
      if (isForeground) {
        terminal.setDefaultForegroundColor(color);
      } else {
        terminal.setDefaultBackgroundColor(color);
      }
    }
  }

  /// Handle OSC 52 - Clipboard operations.
  ///
  /// Format: OSC 52 ; clipboard ; data
  /// clipboard: c (clipboard), p (primary), q (secondary), s (select)
  /// data: base64-encoded string
  static void _handleClipboard(Terminal terminal, String data) {
    final parts = data.split(';');
    if (parts.length >= 2) {
      final clipboardType = parts[0];
      final base64Data = parts[1];

      // For now, just handle basic clipboard operations
      // In a full implementation, you would decode the base64 data
      // and interact with the system clipboard
      terminal.setClipboardData(clipboardType, base64Data);
    }
  }

  /// Parse a color specification string.
  ///
  /// Supports formats:
  /// - rgb:RR/GG/BB (e.g., rgb:ff/00/00 for red)
  /// - rgb:RRRR/GGGG/BBBB (16-bit components)
  /// - #RRGGBB (hex format)
  /// - Named colors (not implemented yet)
  ///
  /// Returns null if the format is not recognized.
  static int? _parseColorSpec(String spec) {
    spec = spec.trim().toLowerCase();

    // rgb:RR/GG/BB or rgb:RRRR/GGGG/BBBB format
    if (spec.startsWith('rgb:')) {
      final parts = spec.substring(4).split('/');
      if (parts.length == 3) {
        // Parse each component and scale to 8-bit if needed
        final r = _parseHexComponent(parts[0]);
        final g = _parseHexComponent(parts[1]);
        final b = _parseHexComponent(parts[2]);

        if (r != null && g != null && b != null) {
          return 0xFF000000 | (r << 16) | (g << 8) | b;
        }
      }
    }

    // #RRGGBB format
    if (spec.startsWith('#') && spec.length == 7) {
      final hex = spec.substring(1);
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        return 0xFF000000 | value;
      }
    }

    return null;
  }

  /// Parse a hex color component and scale to 8-bit.
  ///
  /// Supports:
  /// - 2-digit hex (RR): use directly
  /// - 4-digit hex (RRRR): take most significant byte
  static int? _parseHexComponent(String hex) {
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;

    if (hex.length == 2) {
      // 8-bit component
      return value;
    } else if (hex.length == 4) {
      // 16-bit component - scale to 8-bit (take high byte)
      return value >> 8;
    }

    return null;
  }
}
