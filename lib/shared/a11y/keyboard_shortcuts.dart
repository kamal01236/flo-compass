import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/shell/shell_navigation_controller.dart';
import '../widgets/command_palette.dart';

bool isEditingText() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;
  final ctx = focus.context;
  if (ctx == null) return false;
  if (ctx.widget is EditableText) return true;
  return ctx.findAncestorWidgetOfExactType<TextField>() != null;
}

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          showCommandPalette(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          showCommandPalette(context);
        },
        const SingleActivator(LogicalKeyboardKey.slash, control: true): () {
          showCommandPalette(context);
        },
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _switchTab(context, 0),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _switchTab(context, 1),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _switchTab(context, 2),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _switchTab(context, 3),
      },
      child: child,
    );
  }

  void _switchTab(BuildContext context, int index) {
    if (isEditingText()) return;
    ShellNavigationController.goToTab(index);
  }
}
