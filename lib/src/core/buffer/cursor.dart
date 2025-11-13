import 'package:flutter/foundation.dart';

/// Cursor style options.
enum CursorStyle {
  /// Block cursor: █
  block,

  /// Underline cursor: _
  underline,

  /// Bar cursor: |
  bar,
}

/// Represents the cursor position and appearance in the terminal.
@immutable
class Cursor {
  /// The horizontal position (column), 0-indexed.
  final int x;

  /// The vertical position (row), 0-indexed.
  final int y;

  /// Whether the cursor is visible.
  final bool isVisible;

  /// The visual style of the cursor.
  final CursorStyle style;

  /// Creates a cursor with the given properties.
  const Cursor({
    this.x = 0,
    this.y = 0,
    this.isVisible = true,
    this.style = CursorStyle.block,
  });

  /// Creates a copy of this cursor with some properties replaced.
  Cursor copyWith({
    int? x,
    int? y,
    bool? isVisible,
    CursorStyle? style,
  }) {
    return Cursor(
      x: x ?? this.x,
      y: y ?? this.y,
      isVisible: isVisible ?? this.isVisible,
      style: style ?? this.style,
    );
  }

  /// Moves the cursor up by [n] rows.
  Cursor moveUp(int n) => Cursor(
        x: x,
        y: y - n,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor down by [n] rows.
  Cursor moveDown(int n) => Cursor(
        x: x,
        y: y + n,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor left by [n] columns.
  Cursor moveLeft(int n) => Cursor(
        x: x - n,
        y: y,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor right by [n] columns.
  Cursor moveRight(int n) => Cursor(
        x: x + n,
        y: y,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor to the specified absolute position.
  Cursor moveTo(int newX, int newY) => Cursor(
        x: newX,
        y: newY,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor to the specified column on the current row.
  Cursor moveToColumn(int newX) => Cursor(
        x: newX,
        y: y,
        isVisible: isVisible,
        style: style,
      );

  /// Moves the cursor to the specified row in the current column.
  Cursor moveToRow(int newY) => Cursor(
        x: x,
        y: newY,
        isVisible: isVisible,
        style: style,
      );

  /// Resets the cursor to position (0, 0).
  Cursor reset() => Cursor(
        x: 0,
        y: 0,
        isVisible: isVisible,
        style: style,
      );

  /// Clamps the cursor position within the specified bounds.
  ///
  /// Ensures x is in [0, maxX) and y is in [0, maxY).
  Cursor clamp(int maxX, int maxY) {
    return Cursor(
      x: x.clamp(0, maxX - 1),
      y: y.clamp(0, maxY - 1),
      isVisible: isVisible,
      style: style,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cursor &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          isVisible == other.isVisible &&
          style == other.style;

  @override
  int get hashCode =>
      x.hashCode ^ y.hashCode ^ isVisible.hashCode ^ style.hashCode;

  @override
  String toString() {
    return 'Cursor(x: $x, y: $y, visible: $isVisible, style: $style)';
  }
}
