import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/features/shell/shell_navigation_controller.dart';
import 'package:flo_compass/shared/a11y/keyboard_shortcuts.dart';

void main() {
  int? switchedTab;

  setUp(() {
    switchedTab = null;
    ShellNavigationController.register((index) => switchedTab = index);
  });

  tearDown(() {
    ShellNavigationController.unregister();
  });

  testWidgets('has no autofocus Focus descendant', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: KeyboardShortcuts(child: SizedBox())),
    );

    final focuses = tester.widgetList<Focus>(
      find.descendant(
        of: find.byType(KeyboardShortcuts),
        matching: find.byType(Focus),
      ),
    );
    expect(focuses.every((focus) => !focus.autofocus), isTrue);
  });

  testWidgets('pumps multiple frames without layout exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: KeyboardShortcuts(child: Text('x'))),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'digit shortcut invokes ShellNavigationController when not editing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardShortcuts(
            child: Focus(autofocus: true, child: const SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.digit2);

      expect(switchedTab, 1);
    },
  );

  testWidgets('digit ignored when TextField focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyboardShortcuts(
            child: TextField(controller: TextEditingController()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);

    expect(switchedTab, isNull);
  });
}
