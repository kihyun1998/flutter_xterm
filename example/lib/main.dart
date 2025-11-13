import 'package:flutter/material.dart';
import 'package:flutter_xterm/flutter_xterm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter XTerm - Phase 1 Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TerminalDemo(),
    );
  }
}

class TerminalDemo extends StatefulWidget {
  const TerminalDemo({super.key});

  @override
  State<TerminalDemo> createState() => _TerminalDemoState();
}

class _TerminalDemoState extends State<TerminalDemo> {
  late Terminal terminal;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(rows: 24, cols: 80);

    // Phase 1 demo: Write some sample text
    terminal.write('=== Flutter XTerm Phase 1 Demo ===\n\n');
    terminal.write('Hello, World!\n');
    terminal.write('This is a basic terminal emulator.\n\n');

    // Demonstrate control characters
    terminal.write('Control characters:\n');
    terminal.write('Tab:\there\n');
    terminal.write('Newline works\nLike this\n\n');

    // Demonstrate styled text
    terminal.setStyle(const TerminalCell(isBold: true));
    terminal.write('Bold text ');
    terminal.resetStyle();
    terminal.write('Normal text\n');

    terminal.setStyle(const TerminalCell(isItalic: true));
    terminal.write('Italic text ');
    terminal.resetStyle();
    terminal.write('Normal text\n\n');

    // Demonstrate colors
    terminal.setStyle(const TerminalCell(foregroundColor: Colors.red));
    terminal.write('Red text ');
    terminal.setStyle(const TerminalCell(foregroundColor: Colors.green));
    terminal.write('Green text ');
    terminal.setStyle(const TerminalCell(foregroundColor: Colors.blue));
    terminal.write('Blue text\n');
    terminal.resetStyle();

    terminal.write('\n');
    terminal.write('Cursor position: (${terminal.cursor.x}, ${terminal.cursor.y})\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter XTerm - Phase 1'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terminal Buffer Content:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildTerminalView(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Terminal Info:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Rows: ${terminal.rows}'),
            Text('Cols: ${terminal.cols}'),
            Text('Cursor: (${terminal.cursor.x}, ${terminal.cursor.y})'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  terminal.write('\nNew line added at ${DateTime.now()}\n');
                });
              },
              child: const Text('Add Line'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  terminal.clear();
                  terminal.write('Terminal cleared!\n');
                });
              },
              child: const Text('Clear Terminal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView() {
    final lines = <Widget>[];

    for (int y = 0; y < terminal.rows; y++) {
      final rowWidgets = <InlineSpan>[];

      for (int x = 0; x < terminal.cols; x++) {
        final cell = terminal.buffer.getCell(x, y);

        rowWidgets.add(
          TextSpan(
            text: cell.char,
            style: TextStyle(
              color: cell.foregroundColor ?? Colors.white,
              backgroundColor: cell.backgroundColor,
              fontWeight: cell.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: cell.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration:
                  cell.isUnderline ? TextDecoration.underline : TextDecoration.none,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        );
      }

      lines.add(
        RichText(
          text: TextSpan(children: rowWidgets),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }
}
