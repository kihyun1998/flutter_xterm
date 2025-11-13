import 'package:flutter/material.dart';

/// Represents a single cell in the terminal buffer.
///
/// Each cell contains a character and its styling information including
/// foreground/background colors and text style attributes (bold, italic, underline).
@immutable
class TerminalCell {
  /// The character to display in this cell.
  final String char;

  /// The foreground (text) color. If null, uses the default color.
  final Color? foregroundColor;

  /// The background color. If null, uses the default color.
  final Color? backgroundColor;

  /// Whether the text should be rendered in bold.
  final bool isBold;

  /// Whether the text should be rendered in italic.
  final bool isItalic;

  /// Whether the text should be rendered with underline.
  final bool isUnderline;

  /// Creates a terminal cell with the given properties.
  const TerminalCell({
    this.char = ' ',
    this.foregroundColor,
    this.backgroundColor,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  /// Creates an empty cell with a space character and no styling.
  factory TerminalCell.empty() => const TerminalCell();

  /// Creates a copy of this cell with some properties replaced.
  TerminalCell copyWith({
    String? char,
    Color? foregroundColor,
    Color? backgroundColor,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    return TerminalCell(
      char: char ?? this.char,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
    );
  }

  /// Returns true if this cell is empty (contains only a space with no styling).
  bool get isEmpty =>
      char == ' ' &&
      foregroundColor == null &&
      backgroundColor == null &&
      !isBold &&
      !isItalic &&
      !isUnderline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalCell &&
          runtimeType == other.runtimeType &&
          char == other.char &&
          foregroundColor == other.foregroundColor &&
          backgroundColor == other.backgroundColor &&
          isBold == other.isBold &&
          isItalic == other.isItalic &&
          isUnderline == other.isUnderline;

  @override
  int get hashCode =>
      char.hashCode ^
      foregroundColor.hashCode ^
      backgroundColor.hashCode ^
      isBold.hashCode ^
      isItalic.hashCode ^
      isUnderline.hashCode;

  @override
  String toString() {
    return 'TerminalCell(char: "$char", fg: $foregroundColor, bg: $backgroundColor, '
        'bold: $isBold, italic: $isItalic, underline: $isUnderline)';
  }
}
