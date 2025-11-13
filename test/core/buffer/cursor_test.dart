import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xterm/src/core/buffer/cursor.dart';

void main() {
  group('Cursor', () {
    test('creates default cursor at origin', () {
      const cursor = Cursor();

      expect(cursor.x, 0);
      expect(cursor.y, 0);
      expect(cursor.isVisible, true);
      expect(cursor.style, CursorStyle.block);
    });

    test('creates cursor with custom properties', () {
      const cursor = Cursor(
        x: 10,
        y: 5,
        isVisible: false,
        style: CursorStyle.bar,
      );

      expect(cursor.x, 10);
      expect(cursor.y, 5);
      expect(cursor.isVisible, false);
      expect(cursor.style, CursorStyle.bar);
    });

    test('copyWith creates new cursor with modified properties', () {
      const original = Cursor(x: 10, y: 5);
      final modified = original.copyWith(x: 20);

      expect(modified.x, 20);
      expect(modified.y, 5);
      expect(original.x, 10); // original unchanged
    });

    test('moveUp decreases y coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveUp(3);

      expect(moved.x, 10);
      expect(moved.y, 7);
    });

    test('moveDown increases y coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveDown(3);

      expect(moved.x, 10);
      expect(moved.y, 13);
    });

    test('moveLeft decreases x coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveLeft(3);

      expect(moved.x, 7);
      expect(moved.y, 10);
    });

    test('moveRight increases x coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveRight(3);

      expect(moved.x, 13);
      expect(moved.y, 10);
    });

    test('moveTo sets absolute position', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveTo(5, 3);

      expect(moved.x, 5);
      expect(moved.y, 3);
    });

    test('moveToColumn changes only x coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveToColumn(20);

      expect(moved.x, 20);
      expect(moved.y, 10);
    });

    test('moveToRow changes only y coordinate', () {
      const cursor = Cursor(x: 10, y: 10);
      final moved = cursor.moveToRow(20);

      expect(moved.x, 10);
      expect(moved.y, 20);
    });

    test('reset returns cursor to origin', () {
      const cursor = Cursor(x: 10, y: 10, isVisible: false);
      final reset = cursor.reset();

      expect(reset.x, 0);
      expect(reset.y, 0);
      expect(reset.isVisible, false); // preserves other properties
    });

    test('clamp keeps cursor within bounds', () {
      const cursor = Cursor(x: 10, y: 10);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 10);
      expect(clamped.y, 10);
    });

    test('clamp restricts x to upper bound', () {
      const cursor = Cursor(x: 100, y: 10);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 79); // maxX - 1
      expect(clamped.y, 10);
    });

    test('clamp restricts y to upper bound', () {
      const cursor = Cursor(x: 10, y: 100);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 10);
      expect(clamped.y, 23); // maxY - 1
    });

    test('clamp restricts negative x to 0', () {
      const cursor = Cursor(x: -5, y: 10);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 0);
      expect(clamped.y, 10);
    });

    test('clamp restricts negative y to 0', () {
      const cursor = Cursor(x: 10, y: -5);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 10);
      expect(clamped.y, 0);
    });

    test('clamp handles both coordinates out of bounds', () {
      const cursor = Cursor(x: -10, y: 100);
      final clamped = cursor.clamp(80, 24);

      expect(clamped.x, 0);
      expect(clamped.y, 23);
    });

    test('move operations can result in negative coordinates', () {
      const cursor = Cursor(x: 5, y: 5);
      final moved = cursor.moveLeft(10);

      expect(moved.x, -5);
      // clamp should be used by the caller to restrict bounds
    });

    test('equality works correctly', () {
      const cursor1 = Cursor(x: 10, y: 5, style: CursorStyle.bar);
      const cursor2 = Cursor(x: 10, y: 5, style: CursorStyle.bar);
      const cursor3 = Cursor(x: 10, y: 6, style: CursorStyle.bar);

      expect(cursor1, equals(cursor2));
      expect(cursor1, isNot(equals(cursor3)));
    });

    test('hashCode is consistent with equality', () {
      const cursor1 = Cursor(x: 10, y: 5);
      const cursor2 = Cursor(x: 10, y: 5);

      expect(cursor1.hashCode, equals(cursor2.hashCode));
    });

    test('toString provides useful representation', () {
      const cursor = Cursor(x: 10, y: 5, isVisible: false);
      final str = cursor.toString();

      expect(str, contains('10'));
      expect(str, contains('5'));
      expect(str, contains('false'));
    });

    test('all CursorStyle enum values are accessible', () {
      expect(CursorStyle.block, isNotNull);
      expect(CursorStyle.underline, isNotNull);
      expect(CursorStyle.bar, isNotNull);
    });
  });
}
