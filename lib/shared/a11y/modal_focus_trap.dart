import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Traps focus inside modal sheets and dialogs for keyboard users.
class ModalFocusTrap extends StatefulWidget {
  const ModalFocusTrap({super.key, required this.child});

  final Widget child;

  @override
  State<ModalFocusTrap> createState() => _ModalFocusTrapState();
}

class _ModalFocusTrapState extends State<ModalFocusTrap> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.maybePop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: 'Dialog',
        child: widget.child,
      ),
    );
  }
}
