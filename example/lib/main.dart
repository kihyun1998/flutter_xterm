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
      title: 'Flutter XTerm - Phase 2 Demo',
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

    _initializeTerminalContent();
  }

  void _initializeTerminalContent() {
    // Phase 2 Demo: ANSI Escape Sequences
    terminal.write('\x1b[1;34m=== Flutter XTerm Phase 2 Demo ===\x1b[0m\n');
    terminal.write('\x1b[3mANSI Escape Sequence Support\x1b[0m\n\n');

    // === Colors Demo ===
    terminal.write('\x1b[1mBasic Colors:\x1b[0m\n');
    terminal.write('  \x1b[30mBlack\x1b[0m  ');
    terminal.write('\x1b[31mRed\x1b[0m  ');
    terminal.write('\x1b[32mGreen\x1b[0m  ');
    terminal.write('\x1b[33mYellow\x1b[0m  ');
    terminal.write('\x1b[34mBlue\x1b[0m  ');
    terminal.write('\x1b[35mMagenta\x1b[0m  ');
    terminal.write('\x1b[36mCyan\x1b[0m  ');
    terminal.write('\x1b[37mWhite\x1b[0m\n');

    terminal.write('\n\x1b[1mBright Colors:\x1b[0m\n');
    terminal.write('  \x1b[90mBright Black\x1b[0m  ');
    terminal.write('\x1b[91mBright Red\x1b[0m  ');
    terminal.write('\x1b[92mBright Green\x1b[0m  ');
    terminal.write('\x1b[93mBright Yellow\x1b[0m\n');
    terminal.write('  \x1b[94mBright Blue\x1b[0m  ');
    terminal.write('\x1b[95mBright Magenta\x1b[0m  ');
    terminal.write('\x1b[96mBright Cyan\x1b[0m  ');
    terminal.write('\x1b[97mBright White\x1b[0m\n');

    // === Background Colors ===
    terminal.write('\n\x1b[1mBackground Colors:\x1b[0m\n');
    terminal.write('  \x1b[41;97m Red BG \x1b[0m  ');
    terminal.write('\x1b[42;97m Green BG \x1b[0m  ');
    terminal.write('\x1b[44;97m Blue BG \x1b[0m  ');
    terminal.write('\x1b[43;30m Yellow BG \x1b[0m\n');

    // === Text Styles ===
    terminal.write('\n\x1b[1mText Styles:\x1b[0m\n');
    terminal.write('  \x1b[1mBold\x1b[0m  ');
    terminal.write('\x1b[3mItalic\x1b[0m  ');
    terminal.write('\x1b[4mUnderline\x1b[0m  ');
    terminal.write('\x1b[1;3;4mAll Combined\x1b[0m\n');

    // === RGB Colors (True Color) ===
    terminal.write('\n\x1b[1mRGB True Color:\x1b[0m\n');
    terminal.write('  \x1b[38;2;255;0;0mRGB Red\x1b[0m  ');
    terminal.write('\x1b[38;2;0;255;0mRGB Green\x1b[0m  ');
    terminal.write('\x1b[38;2;0;0;255mRGB Blue\x1b[0m\n');
    terminal.write('  \x1b[38;2;255;165;0mOrange\x1b[0m  ');
    terminal.write('\x1b[38;2;128;0;128mPurple\x1b[0m  ');
    terminal.write('\x1b[38;2;255;192;203mPink\x1b[0m\n');

    // === 256 Color Palette Sample ===
    terminal.write('\n\x1b[1m256 Color Palette (sample):\x1b[0m\n');
    terminal.write('  ');
    for (int i = 196; i <= 201; i++) {
      terminal.write('\x1b[38;5;${i}m█\x1b[0m');
    }
    terminal.write('  ');
    for (int i = 46; i <= 51; i++) {
      terminal.write('\x1b[38;5;${i}m█\x1b[0m');
    }
    terminal.write('  ');
    for (int i = 21; i <= 26; i++) {
      terminal.write('\x1b[38;5;${i}m█\x1b[0m');
    }
    terminal.write('\n');

    // === Complex Example ===
    terminal.write('\n\x1b[1mComplex Example (simulated ls --color):\x1b[0m\n');
    terminal.write('  file.txt\n');
    terminal.write('  \x1b[1;34mdirectory\x1b[0m\n');
    terminal.write('  \x1b[1;32mexecutable.sh\x1b[0m\n');
    terminal.write('  \x1b[1;31mimage.png\x1b[0m\n');

    // === Cursor Movement Demo ===
    terminal.write('\n\x1b[1mCursor Movement:\x1b[0m\n');
    terminal.write('Start ');
    terminal.write('\x1b[10C'); // Move right 10
    terminal.write('→Right');
    terminal.write('\x1b[5D'); // Move left 5
    terminal.write('\x1b[1B'); // Move down 1
    terminal.write('↓Down\n\n');

    // === Title Update ===
    terminal.write('\x1b]2;Flutter XTerm Demo\x07'); // Set title

    terminal.write('\x1b[2mTitle: "${terminal.title}"\x1b[0m\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter XTerm - Phase 3'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terminal View:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildTerminalView(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Interactive Demos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      terminal.write('\n\x1b[1;32m✓ Button clicked!\x1b[0m\n');
                    });
                  },
                  child: const Text('Add Green Text'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      terminal.write('\x1b[H\x1b[2J'); // Clear screen
                      terminal.write('\x1b[1;33mScreen cleared!\x1b[0m\n');
                    });
                  },
                  child: const Text('Clear Screen (CSI 2J)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      terminal.write('\x1b[10;20H'); // Move to 10,20
                      terminal.write('\x1b[41;97m X \x1b[0m');
                    });
                  },
                  child: const Text('Move Cursor (CSI H)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Rainbow text
                      final colors = [31, 33, 32, 36, 34, 35];
                      final text = 'RAINBOW';
                      for (int i = 0; i < text.length; i++) {
                        terminal.write(
                            '\x1b[1;${colors[i % colors.length]}m${text[i]}\x1b[0m');
                      }
                      terminal.write('\n');
                    });
                  },
                  child: const Text('Rainbow Text'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      terminal.reset();
                      _initializeTerminalContent();
                    });
                  },
                  child: const Text('Reset Terminal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terminal Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Rows: ${terminal.rows}'),
                    Text('Cols: ${terminal.cols}'),
                    Text('Cursor: (${terminal.cursor.x}, ${terminal.cursor.y})'),
                    Text('Title: "${terminal.title}"'),
                    Text('Cursor Visible: ${terminal.cursor.isVisible}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView() {
    return TerminalView(
      terminal: terminal,
      theme: TerminalTheme.dark(),
    );
  }
}
