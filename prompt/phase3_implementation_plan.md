# Phase 3: UI 렌더링 구현 기획

## 1. 개요

Phase 3에서는 Terminal 데이터를 실제 화면에 렌더링하는 UI 레이어를 구축합니다.
현재 example/lib/main.dart에 임시 렌더링 코드가 있지만, 이를 재사용 가능한 위젯으로 리팩토링합니다.

### 현재 상태 분석

**example/lib/main.dart:243-281**에 임시 렌더링 구현:
- RichText + TextSpan으로 셀별 렌더링
- 매 프레임마다 전체 버퍼를 재생성 (비효율적)
- 커서 깜빡임 없음
- 재사용 불가능 (데모 앱에 종속)
- 성능 최적화 없음

### 목표

✅ **재사용 가능한 위젯**: 다른 프로젝트에서 `TerminalView(terminal: myTerminal)` 형태로 사용 가능
✅ **고성능 렌더링**: CustomPainter 사용, TextPainter 캐싱, 더티 영역만 다시 그리기
✅ **커서 깜빡임**: AnimationController로 부드러운 깜빡임 효과
✅ **테마 지원**: 폰트, 색상, 커서 스타일 커스터마이징 가능
✅ **정확한 레이아웃**: 고정폭 폰트 사용, 셀 크기 정확히 계산

---

## 2. 파일 구조

```
lib/src/ui/                          # 새로 생성할 디렉토리
  ├── terminal_view.dart             # TerminalView 위젯 (메인 진입점)
  ├── terminal_painter.dart          # TerminalPainter (CustomPainter)
  ├── terminal_theme.dart            # TerminalTheme (테마 설정)
  └── text_style_cache.dart          # TextPainter 캐싱 유틸리티
```

**lib/flutter_xterm.dart**에 다음 export 추가:
```dart
// UI - Terminal View
export 'src/ui/terminal_view.dart';
export 'src/ui/terminal_theme.dart';
```

내부 구현 파일(`terminal_painter.dart`, `text_style_cache.dart`)는 export하지 않음 (구현 세부사항)

---

## 3. 각 파일별 상세 설계

### 3.1 terminal_theme.dart

**위치**: `lib/src/ui/terminal_theme.dart`

**역할**: 터미널 렌더링에 필요한 모든 스타일 설정을 관리

**클래스 설계**:

```dart
@immutable
class TerminalTheme {
  // === 폰트 설정 ===
  final String fontFamily;           // 고정폭 폰트 (기본: 'monospace')
  final double fontSize;              // 폰트 크기 (기본: 14.0)

  // === 색상 설정 ===
  final Color defaultForegroundColor; // 기본 전경색 (기본: Colors.white)
  final Color defaultBackgroundColor; // 기본 배경색 (기본: Colors.black)

  // === 커서 설정 ===
  final CursorStyle cursorStyle;      // 커서 모양 (블록/언더라인/바)
  final Color cursorColor;            // 커서 색상 (기본: Colors.white)
  final Duration cursorBlinkInterval; // 깜빡임 간격 (기본: 530ms)

  // === 레이아웃 ===
  final double lineHeight;            // 라인 높이 배율 (기본: 1.2)
  final EdgeInsets padding;           // 터미널 여백 (기본: EdgeInsets.all(8))

  // === 색상 팔레트 ===
  final List<Color>? customPalette;   // 커스텀 256색 팔레트 (null이면 AnsiColors 사용)

  // 셀 크기 계산 (캐싱)
  Size? _cachedCellSize;

  Size get cellSize {
    if (_cachedCellSize != null) return _cachedCellSize!;

    // TextPainter로 'W' 문자의 크기 측정
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'W',
        style: TextStyle(fontFamily: fontFamily, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _cachedCellSize = Size(
      textPainter.width,
      textPainter.height * lineHeight,
    );
    return _cachedCellSize!;
  }

  // 기본 생성자, copyWith, 미리 정의된 테마 (light, dark) 등
}

enum CursorStyle {
  block,       // █ 블록 커서
  underline,   // _ 언더라인 커서
  bar,         // | 바 커서
}
```

**주요 메서드**:
- `TerminalTheme()`: 기본 생성자
- `TerminalTheme.light()`: 밝은 테마
- `TerminalTheme.dark()`: 어두운 테마 (기본)
- `copyWith()`: 일부 속성만 변경한 새 테마 생성
- `cellSize` getter: 폰트 크기 기반으로 셀 크기 계산 및 캐싱

**연결**:
- `AnsiColors` (lib/src/utils/ansi_colors.dart) 사용하여 색상 팔레트 제공
- `TerminalView`와 `TerminalPainter`가 이 테마를 받아서 렌더링에 사용

---

### 3.2 text_style_cache.dart

**위치**: `lib/src/ui/text_style_cache.dart`

**역할**: 동일한 스타일의 TextPainter를 캐싱하여 성능 향상

**클래스 설계**:

```dart
class TextStyleCache {
  // 캐시 맵: (스타일 해시) -> TextPainter
  final Map<int, TextPainter> _cache = {};

  // 최대 캐시 크기 (메모리 사용 제한)
  static const int maxCacheSize = 256;

  // TextPainter 가져오기 (없으면 생성)
  TextPainter getPainter(TerminalCell cell, TerminalTheme theme) {
    final hash = _computeStyleHash(cell, theme);

    if (_cache.containsKey(hash)) {
      return _cache[hash]!;
    }

    // 캐시 크기 제한
    if (_cache.length >= maxCacheSize) {
      _cache.clear(); // 단순 전체 클리어 (LRU는 복잡도 증가)
    }

    // 새 TextPainter 생성
    final painter = TextPainter(
      text: TextSpan(
        text: cell.char,
        style: _buildTextStyle(cell, theme),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _cache[hash] = painter;
    return painter;
  }

  // 스타일 해시 계산
  int _computeStyleHash(TerminalCell cell, TerminalTheme theme) {
    return Object.hash(
      cell.foregroundColor ?? theme.defaultForegroundColor,
      cell.backgroundColor ?? theme.defaultBackgroundColor,
      cell.isBold,
      cell.isItalic,
      cell.isUnderline,
      theme.fontFamily,
      theme.fontSize,
    );
  }

  // TextStyle 생성
  TextStyle _buildTextStyle(TerminalCell cell, TerminalTheme theme) {
    return TextStyle(
      fontFamily: theme.fontFamily,
      fontSize: theme.fontSize,
      color: cell.foregroundColor ?? theme.defaultForegroundColor,
      backgroundColor: cell.backgroundColor ?? theme.defaultBackgroundColor,
      fontWeight: cell.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: cell.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: cell.isUnderline ? TextDecoration.underline : TextDecoration.none,
      height: theme.lineHeight,
    );
  }

  // 캐시 클리어 (테마 변경 시 호출)
  void clear() {
    _cache.clear();
  }
}
```

**최적화 전략**:
- 동일한 스타일의 텍스트는 캐시된 TextPainter 재사용
- 해시 기반 캐시 (색상, bold, italic, underline, 폰트 조합)
- 최대 256개 캐시 (메모리 사용 제한)
- 테마 변경 시 캐시 초기화

**연결**:
- `TerminalPainter`가 내부적으로 사용
- `TerminalCell`과 `TerminalTheme`를 조합해서 TextPainter 생성

---

### 3.3 terminal_painter.dart

**위치**: `lib/src/ui/terminal_painter.dart`

**역할**: Terminal 버퍼를 Canvas에 그리는 CustomPainter

**클래스 설계**:

```dart
class TerminalPainter extends CustomPainter {
  final Terminal terminal;
  final TerminalTheme theme;
  final bool showCursor;              // 커서 표시 여부 (깜빡임용)
  final TextStyleCache _textCache;    // TextPainter 캐시

  TerminalPainter({
    required this.terminal,
    required this.theme,
    this.showCursor = true,
  }) : _textCache = TextStyleCache();

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = theme.cellSize;

    // 1. 배경 그리기 (전체 터미널 배경)
    _drawBackground(canvas, size);

    // 2. 각 셀 그리기 (배경색 + 텍스트)
    for (int y = 0; y < terminal.rows; y++) {
      for (int x = 0; x < terminal.cols; x++) {
        final cell = terminal.buffer.getCell(x, y);
        final offset = Offset(
          theme.padding.left + x * cellSize.width,
          theme.padding.top + y * cellSize.height,
        );

        // 셀 배경색 그리기 (있는 경우)
        if (cell.backgroundColor != null) {
          _drawCellBackground(canvas, offset, cellSize, cell.backgroundColor!);
        }

        // 텍스트 그리기
        if (cell.char != ' ') {
          _drawText(canvas, offset, cell);
        }
      }
    }

    // 3. 커서 그리기
    if (showCursor && terminal.cursor.isVisible) {
      _drawCursor(canvas, cellSize);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = theme.defaultBackgroundColor;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawCellBackground(Canvas canvas, Offset offset, Size cellSize, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRect(offset & cellSize, paint);
  }

  void _drawText(Canvas canvas, Offset offset, TerminalCell cell) {
    final textPainter = _textCache.getPainter(cell, theme);
    textPainter.paint(canvas, offset);
  }

  void _drawCursor(Canvas canvas, Size cellSize) {
    final cursor = terminal.cursor;
    final offset = Offset(
      theme.padding.left + cursor.x * cellSize.width,
      theme.padding.top + cursor.y * cellSize.height,
    );

    final paint = Paint()
      ..color = theme.cursorColor
      ..style = PaintingStyle.fill;

    switch (theme.cursorStyle) {
      case CursorStyle.block:
        // 블록 커서: 셀 전체를 채움
        canvas.drawRect(offset & cellSize, paint);
        break;
      case CursorStyle.underline:
        // 언더라인 커서: 하단 2px
        canvas.drawRect(
          Rect.fromLTWH(offset.dx, offset.dy + cellSize.height - 2, cellSize.width, 2),
          paint,
        );
        break;
      case CursorStyle.bar:
        // 바 커서: 좌측 2px
        canvas.drawRect(
          Rect.fromLTWH(offset.dx, offset.dy, 2, cellSize.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(TerminalPainter oldDelegate) {
    // 터미널 인스턴스가 다르거나 커서 표시 상태가 변경되면 다시 그리기
    return oldDelegate.terminal != terminal ||
           oldDelegate.showCursor != showCursor ||
           oldDelegate.theme != theme;
  }
}
```

**렌더링 순서**:
1. 전체 배경색 그리기 (defaultBackgroundColor)
2. 각 셀의 배경색 그리기 (있는 경우)
3. 각 셀의 텍스트 그리기 (공백 제외)
4. 커서 그리기 (visible && showCursor)

**성능 최적화**:
- `shouldRepaint()`: 터미널 인스턴스, 커서 상태, 테마가 변경된 경우에만 다시 그리기
- `TextStyleCache` 사용으로 동일한 스타일의 TextPainter 재사용
- 공백 문자는 그리기 생략 (배경색만 그림)

**연결**:
- `Terminal` (lib/src/core/terminal/terminal.dart)에서 버퍼 데이터 읽기
- `TerminalTheme`에서 스타일 정보 가져오기
- `TerminalView`에서 CustomPaint의 painter로 사용

---

### 3.4 terminal_view.dart

**위치**: `lib/src/ui/terminal_view.dart`

**역할**: 사용자가 사용할 메인 위젯 (공개 API)

**클래스 설계**:

```dart
class TerminalView extends StatefulWidget {
  final Terminal terminal;
  final TerminalTheme? theme;         // null이면 TerminalTheme.dark() 사용

  const TerminalView({
    Key? key,
    required this.terminal,
    this.theme,
  }) : super(key: key);

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView>
    with SingleTickerProviderStateMixin {

  late AnimationController _cursorBlinkController;
  bool _showCursor = true;
  late TerminalTheme _effectiveTheme;

  @override
  void initState() {
    super.initState();

    _effectiveTheme = widget.theme ?? TerminalTheme.dark();

    // 커서 깜빡임 애니메이션 설정
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: _effectiveTheme.cursorBlinkInterval,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showCursor = !_showCursor);
        _cursorBlinkController.reset();
        _cursorBlinkController.forward();
      }
    });

    _cursorBlinkController.forward();
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 테마 변경 감지
    if (widget.theme != oldWidget.theme) {
      _effectiveTheme = widget.theme ?? TerminalTheme.dark();

      // 커서 깜빡임 간격 업데이트
      _cursorBlinkController.duration = _effectiveTheme.cursorBlinkInterval;
    }

    // 터미널 변경 시 다시 그리기 (setState 호출은 프레임워크가 자동 처리)
  }

  @override
  void dispose() {
    _cursorBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = _effectiveTheme.cellSize;

    // 터미널 크기 계산
    final terminalSize = Size(
      _effectiveTheme.padding.horizontal + widget.terminal.cols * cellSize.width,
      _effectiveTheme.padding.vertical + widget.terminal.rows * cellSize.height,
    );

    return Container(
      width: terminalSize.width,
      height: terminalSize.height,
      color: _effectiveTheme.defaultBackgroundColor,
      child: CustomPaint(
        size: terminalSize,
        painter: TerminalPainter(
          terminal: widget.terminal,
          theme: _effectiveTheme,
          showCursor: _showCursor,
        ),
      ),
    );
  }
}
```

**주요 기능**:

1. **커서 깜빡임**:
   - `AnimationController`로 깜빡임 타이밍 관리
   - `_showCursor` 플래그로 on/off 토글
   - 기본 530ms 간격 (테마에서 설정 가능)

2. **크기 계산**:
   - 셀 크기 × (rows, cols) + 패딩
   - 고정 크기 Container로 감싸기

3. **테마 관리**:
   - `widget.theme`가 null이면 `TerminalTheme.dark()` 사용
   - 테마 변경 시 자동으로 적용 (`didUpdateWidget`)

4. **상태 변경 감지**:
   - **중요**: Terminal 객체가 변경될 때 자동으로 다시 그려지도록 설계
   - **Phase 5 이후 개선 필요**: `ChangeNotifier` 또는 `ValueListenable`로 Terminal 내부 변경 감지
     - 현재: `terminal.write("text")` 후 `setState(() {})` 수동 호출 필요 (example 앱 참고)
     - 향후: Terminal이 ChangeNotifier를 implement하고 `notifyListeners()` 호출
     - TerminalView가 `addListener()`로 자동 감지

**Phase 3에서의 사용 방식** (example/lib/main.dart 수정):

```dart
// Before (Phase 2):
Widget _buildTerminalView() {
  final lines = <Widget>[];
  for (int y = 0; y < terminal.rows; y++) {
    // ... 복잡한 RichText 생성 코드 ...
  }
  return Column(children: lines);
}

// After (Phase 3):
Widget _buildTerminalView() {
  return TerminalView(
    terminal: terminal,
    theme: TerminalTheme.dark(),
  );
}
```

**연결**:
- `Terminal` 인스턴스를 받아서 렌더링
- `TerminalPainter`를 CustomPaint의 painter로 사용
- 사용자는 이 위젯만 import해서 사용

---

## 4. 데이터 흐름

```
Terminal (데이터 모델)
   ↓
   ├─ terminal.buffer (TerminalBuffer)
   │     ↓
   │     └─ buffer.getCell(x, y) → TerminalCell
   │
   └─ terminal.cursor (Cursor)

TerminalView (위젯)
   ↓
   ├─ AnimationController → _showCursor (커서 깜빡임)
   │
   └─ CustomPaint
         ↓
         └─ TerminalPainter
               ↓
               ├─ Terminal에서 셀 데이터 읽기
               ├─ TerminalTheme에서 스타일 읽기
               ├─ TextStyleCache로 TextPainter 캐싱
               └─ Canvas에 그리기
                     ↓
                     ├─ 배경 그리기
                     ├─ 각 셀 그리기 (배경 + 텍스트)
                     └─ 커서 그리기
```

---

## 5. 구현 순서

### Step 1: TerminalTheme 구현
- 파일: `lib/src/ui/terminal_theme.dart`
- 의존성: `package:flutter/material.dart`
- 테스트: 테마 생성, cellSize 계산 확인

### Step 2: TextStyleCache 구현
- 파일: `lib/src/ui/text_style_cache.dart`
- 의존성: `terminal_theme.dart`, `../core/buffer/terminal_cell.dart`
- 테스트: 캐시 히트율, 스타일 해시 충돌 확인

### Step 3: TerminalPainter 구현
- 파일: `lib/src/ui/terminal_painter.dart`
- 의존성: `terminal_theme.dart`, `text_style_cache.dart`, `../core/terminal/terminal.dart`
- 테스트: 간단한 버퍼로 렌더링 확인 (스크린샷 비교)

### Step 4: TerminalView 구현
- 파일: `lib/src/ui/terminal_view.dart`
- 의존성: `terminal_painter.dart`, `terminal_theme.dart`
- 테스트: 커서 깜빡임, 크기 계산, 테마 변경 확인

### Step 5: Export 업데이트
- 파일: `lib/flutter_xterm.dart`
- UI 위젯 export 추가

### Step 6: Example 앱 리팩토링
- 파일: `example/lib/main.dart`
- `_buildTerminalView()` 메서드를 `TerminalView` 위젯으로 교체
- 불필요한 렌더링 코드 삭제

---

## 6. 테스트 계획

### 단위 테스트 (test/ui/)
- `terminal_theme_test.dart`: 테마 생성, cellSize 계산
- `text_style_cache_test.dart`: 캐시 동작, 해시 충돌

### 위젯 테스트 (test/ui/)
- `terminal_view_test.dart`: 위젯 렌더링, 크기 계산
- `terminal_painter_test.dart`: CustomPainter 동작 (goldens)

### 통합 테스트 (example 앱)
- 다양한 ANSI 시퀀스 렌더링 확인
- 커서 깜빡임 육안 확인
- 성능 측정 (FPS, 렌더링 시간)

---

## 7. 성능 고려사항

### 현재 Phase 3 최적화
1. **TextPainter 캐싱**: 동일한 스타일은 재사용
2. **shouldRepaint 최적화**: 필요한 경우에만 다시 그리기
3. **공백 스킵**: 공백 문자는 그리기 생략

### 향후 최적화 (Phase 3.3 또는 Phase 6)
1. **더티 영역 추적**: 변경된 셀만 다시 그리기
   - Terminal에 `List<Rect> dirtyRegions` 추가
   - TerminalPainter에서 더티 영역만 렌더링
2. **레이어 분리**: 배경, 텍스트, 커서를 별도 레이어로 관리
3. **오프스크린 렌더링**: Picture 캐싱

---

## 8. 향후 확장 계획

### Phase 4 준비사항
- `TerminalView`에 키보드 입력 핸들러 추가 예정
- `GestureDetector`로 마우스 이벤트 처리 추가

### Phase 6 준비사항
- 텍스트 선택을 위한 SelectionPainter 추가
- 스크롤을 위한 ScrollController 연동

### Phase 7 준비사항
- `TerminalTheme`에 다양한 미리 정의된 테마 추가
  - `TerminalTheme.solarized()`
  - `TerminalTheme.dracula()`
  - `TerminalTheme.nord()` 등

---

## 9. 주요 의사결정

### 9.1 CustomPainter vs RichText
- **선택**: CustomPainter
- **이유**:
  - 더 세밀한 제어 (커서 그리기, 배경 렌더링)
  - 더 나은 성능 (TextPainter 캐싱, 더티 영역 최적화 가능)
  - 픽셀 퍼펙트 렌더링 (셀 크기 정확히 제어)

### 9.2 StatefulWidget vs StatelessWidget
- **선택**: StatefulWidget (TerminalView)
- **이유**:
  - 커서 깜빡임을 위한 AnimationController 필요
  - 내부 상태 (_showCursor) 관리 필요

### 9.3 Terminal 변경 감지 방식
- **Phase 3 방식**: 수동 `setState()` 호출
  - 간단하고 명확
  - example 앱에서는 충분
- **Phase 5 이후**: ChangeNotifier 또는 ValueListenable
  - Terminal이 `ChangeNotifier` implement
  - `write()` 호출 시 자동으로 `notifyListeners()`
  - TerminalView가 `addListener()`로 감지

### 9.4 캐시 전략
- **선택**: Map 기반 단순 캐시 + 크기 제한
- **이유**:
  - LRU 캐시는 복잡도 증가, 터미널에서는 불필요
  - 256개 제한이면 대부분의 경우 충분 (16 기본색 × 2 bold × 2 italic × 2 underline = 128)

---

## 10. Phase 3 완료 체크리스트

- [ ] `lib/src/ui/terminal_theme.dart` 구현
  - [ ] TerminalTheme 클래스
  - [ ] CursorStyle enum
  - [ ] cellSize 계산
  - [ ] 미리 정의된 테마 (dark, light)

- [ ] `lib/src/ui/text_style_cache.dart` 구현
  - [ ] TextStyleCache 클래스
  - [ ] getPainter() 메서드
  - [ ] 스타일 해시 계산
  - [ ] 캐시 크기 제한

- [ ] `lib/src/ui/terminal_painter.dart` 구현
  - [ ] TerminalPainter 클래스
  - [ ] paint() 메서드
  - [ ] _drawBackground(), _drawText(), _drawCursor()
  - [ ] shouldRepaint() 최적화

- [ ] `lib/src/ui/terminal_view.dart` 구현
  - [ ] TerminalView 위젯
  - [ ] 커서 깜빡임 AnimationController
  - [ ] 크기 계산
  - [ ] 테마 관리

- [ ] `lib/flutter_xterm.dart` export 업데이트
  - [ ] TerminalView export
  - [ ] TerminalTheme export

- [ ] `example/lib/main.dart` 리팩토링
  - [ ] _buildTerminalView()를 TerminalView로 교체
  - [ ] 불필요한 코드 삭제
  - [ ] 테마 전환 버튼 추가 (선택사항)

- [ ] 테스트 작성
  - [ ] terminal_theme_test.dart
  - [ ] terminal_view_test.dart (위젯 테스트)

- [ ] flutter analyze 통과
- [ ] example 앱에서 동작 확인
  - [ ] 색상 렌더링
  - [ ] 스타일 (bold, italic, underline)
  - [ ] 커서 깜빡임
  - [ ] 크기 계산

- [ ] dev_plan.md 업데이트 (Phase 3 체크박스 완료 표시)

---

## 11. 예상 코드 라인 수

| 파일 | 예상 라인 수 | 설명 |
|------|-------------|------|
| terminal_theme.dart | ~150 | 테마 클래스, enum, 미리 정의된 테마 |
| text_style_cache.dart | ~80 | 캐시 클래스, 해시 계산 |
| terminal_painter.dart | ~120 | CustomPainter, 렌더링 로직 |
| terminal_view.dart | ~100 | 위젯, 커서 애니메이션 |
| **합계** | **~450** | 주석 포함 |

---

## 12. 참고 자료

- Flutter CustomPainter: https://api.flutter.dev/flutter/rendering/CustomPainter-class.html
- Flutter TextPainter: https://api.flutter.dev/flutter/painting/TextPainter-class.html
- xterm.js 렌더링: https://github.com/xtermjs/xterm.js/tree/master/src/browser/renderer
- Alacritty 렌더링: https://github.com/alacritty/alacritty/tree/master/alacritty/src/renderer

---

이 기획서는 Phase 3 구현을 위한 완전한 가이드입니다.
각 파일의 역할, 클래스 설계, 데이터 흐름, 구현 순서가 명확히 정의되어 있습니다.
