import 'package:flutter/material.dart';

typedef ShellScrollOffsetCallback =
    void Function(double offset, {required bool atTop});

/// Lets [MainShell] trigger scroll-to-top and track scroll offset from tab bodies.
///
/// Conceptually a shell scroll bridge; filename kept for import stability.
class DiscoverScrollBridge extends InheritedWidget {
  const DiscoverScrollBridge({
    super.key,
    required this.register,
    this.registerScrollToBottom,
    this.onScrollOffset,
    required super.child,
  });

  /// Scroll-to-top for Discover, My Plan, and Profile (one active tab body at a time).
  final void Function(VoidCallback? callback) register;

  /// Scroll-to-bottom for the Companion ask flow (latest answer + input).
  final void Function(VoidCallback? callback)? registerScrollToBottom;
  final ShellScrollOffsetCallback? onScrollOffset;

  static DiscoverScrollBridge? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DiscoverScrollBridge>();
  }

  void reportScrollOffset(double offset, {required bool atTop}) {
    onScrollOffset?.call(offset, atTop: atTop);
  }

  @override
  bool updateShouldNotify(DiscoverScrollBridge oldWidget) =>
      onScrollOffset != oldWidget.onScrollOffset;
}
