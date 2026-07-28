import 'package:flutter/material.dart';
import 'package:flo_compass/l10n/app_localizations.dart';

import 'common/common_widgets.dart';

/// Unified loading / error / empty / data states.
class FloAsyncView<T> extends StatelessWidget {
  const FloAsyncView({
    super.key,
    required this.loading,
    required this.error,
    required this.data,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.emptyWhen,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyAction,
    this.retryLabel,
    this.loadingLabel,
  });

  final bool loading;
  final String? error;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final bool Function(T data)? emptyWhen;
  final String? emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final Widget? emptyAction;
  final String? retryLabel;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loading) {
      return loadingWidget ??
          Center(
            child: Semantics(
              label: loadingLabel ?? l10n.loading,
              child: const CircularProgressIndicator(),
            ),
          );
    }
    if (error != null) {
      return ErrorView(
        technicalDetail: error,
        onRetry: onRetry,
        retryLabel: retryLabel,
      );
    }
    final value = data;
    if (value == null) {
      return EmptyState(
        title: emptyTitle ?? l10n.emptyTitle,
        message: emptyMessage,
        icon: emptyIcon ?? Icons.inbox_outlined,
        action: emptyAction,
      );
    }
    if (emptyWhen != null && emptyWhen!(value)) {
      return EmptyState(
        title: emptyTitle ?? l10n.emptyTitle,
        message: emptyMessage,
        icon: emptyIcon ?? Icons.inbox_outlined,
        action: emptyAction,
      );
    }
    return builder(context, value);
  }
}
