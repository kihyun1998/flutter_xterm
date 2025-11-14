/// Parser state for ANSI escape sequence state machine.
///
/// Based on VT100/xterm standard state machine.
/// Reference: https://vt100.net/emu/dec_ansi_parser
enum ParserState {
  /// Ground state - processing normal text characters
  ground,

  /// ESC detected (\x1b)
  escape,

  /// ESC followed by intermediate characters
  escapeIntermediate,

  /// CSI entry state (ESC [)
  csiEntry,

  /// Reading CSI parameters (digits and semicolons)
  csiParam,

  /// CSI intermediate characters
  csiIntermediate,

  /// OSC string state (ESC ])
  oscString,

  /// DCS entry state (ESC P)
  dcsEntry,

  /// DCS parameter state
  dcsParam,

  /// DCS string state
  dcsPassthrough,
}
