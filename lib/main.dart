import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    //size: Size(200, 200),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    //titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setAsFrameless();
    await windowManager.setMinimumSize(const Size(0, 0));
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum AppState {
  bouncingWindow,
  cursor,
  menu,
}

class _MyAppState extends State<MyApp> {
  AppState state = AppState.menu;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppState.menu:
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Launcher', style: TextStyle(fontSize: 30)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        state = AppState.bouncingWindow;
                      });
                    },
                    child: const Text('BouncingWindow'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        windowManager.setTitleBarStyle(TitleBarStyle.hidden);
                        state = AppState.cursor;
                      });
                    },
                    child: const Text('CustomCursor'),
                  ),
                ],
              ),
            ),
          ),
        );
      case AppState.bouncingWindow:
        return const BouncingWindow();

      case AppState.cursor:
        return const CursorWindow();
    }
  }
}

class BouncingWindow extends StatefulWidget {
  const BouncingWindow({super.key});

  @override
  State<StatefulWidget> createState() {
    return BouncingWindowState();
  }
}

class BouncingWindowState extends State<BouncingWindow> {
  BouncingWindowState();
  int acceleration = 0;
  int hAcc = 0;
  bool started = false;
  bool onGround = false;

  @override
  void initState() {
    initState2();
    super.initState();
  }

  void initState2() async {
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    await windowManager.setResizable(false);

    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setBounds(null,
        size: const Size(200, 200),
        position: primaryDisplay.visibleSize!
            .center(primaryDisplay.visiblePosition ?? Offset.zero));
    Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), (timer) async {
      if (!(await windowManager.isFocused())) {
        await windowManager.focus();
      }
      onGround = false;
      double height = primaryDisplay.size.height;

      Offset origPos = (await windowManager.getBounds()).topLeft;
      Offset newPos = Offset(origPos.dx, origPos.dy + acceleration);
      if (origPos.dy + 200 + acceleration > height) {
        acceleration = 0;
        onGround = true;
        newPos = Offset(origPos.dx, height - 200);
      }
      if (origPos.dy + acceleration < 0) {
        acceleration = 0;
        newPos = Offset(origPos.dx, 0);
      }
      windowManager.setBounds(
        null,
        position: newPos,
      );
      acceleration += 1;
      double width = primaryDisplay.size.width;

      origPos = (await windowManager.getBounds()).topLeft;
      newPos = Offset(origPos.dx + hAcc, origPos.dy);
      if (origPos.dx + 200 + hAcc > width) {
        newPos = Offset(width - 200, origPos.dy);
      }
      if (origPos.dx + hAcc < 0) {
        newPos = Offset(0, origPos.dy);
      }
      windowManager.setBounds(
        null,
        position: newPos,
      );
      acceleration += 1;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          onKey: (a, b) {
            if (b.repeat) return KeyEventResult.handled;
            if (b is RawKeyDownEvent) {
              if ((b.logicalKey == LogicalKeyboardKey.keyW ||
                      b.logicalKey == LogicalKeyboardKey.comma) &&
                  onGround) {
                acceleration = -40;
                return KeyEventResult.handled;
              }
              if (b.logicalKey == LogicalKeyboardKey.keyA) {
                hAcc -= 10;
                return KeyEventResult.handled;
              }
              if (b.logicalKey == LogicalKeyboardKey.keyD ||
                  b.logicalKey == LogicalKeyboardKey.keyE) {
                hAcc += 10;
                return KeyEventResult.handled;
              }
            }
            if (b is RawKeyUpEvent) {
              if (b.logicalKey == LogicalKeyboardKey.keyA) {
                hAcc += 10;
                return KeyEventResult.handled;
              }
              if (b.logicalKey == LogicalKeyboardKey.keyD ||
                  b.logicalKey == LogicalKeyboardKey.keyE) {
                hAcc -= 10;
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          autofocus: true,
          child: Container(
            color: Colors.yellow,
          ),
        ),
      ),
    );
  }
}

class CursorWindow extends StatelessWidget {
  const CursorWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MouseRegion(
        opaque: false,
        child: const Center(
            child: Icon(
          Icons.mouse,
          color: Colors.white,
        )),
        onHover: (p) async {
          await windowManager.setBounds(
            null,
            position: (await windowManager.getBounds()).topLeft +
                p.position -
                ((await windowManager.getBounds()).size / 2)
                    .bottomRight(Offset.zero),
          );
        },
      ),
    );
  }
}
