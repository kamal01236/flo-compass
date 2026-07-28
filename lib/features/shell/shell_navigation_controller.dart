import 'package:flutter/material.dart';

/// Shell tab switching for keyboard shortcuts (digits 1–4).
class ShellNavigationController {
  ShellNavigationController._();

  static void Function(int index)? _goToTab;

  static void register(void Function(int index) goToTab) {
    _goToTab = goToTab;
  }

  static void unregister() {
    _goToTab = null;
  }

  static void goToTab(int index) {
    _goToTab?.call(index);
  }
}

bool isEditingText() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;
  final ctx = focus.context;
  if (ctx == null) return false;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}
