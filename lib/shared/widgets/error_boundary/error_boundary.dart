import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../features/feedback/feedback_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../utils/friendly_error_messages.dart';
import '../../utils/web_reload.dart';
import '../common/common_widgets.dart';

class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    required this.runtimeError,
  });

  final Widget child;
  final ValueNotifier<Object?> runtimeError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  int _remountKey = 0;

  void _retry() {
    if (kIsWeb) {
      reloadAppPage();
      return;
    }
    widget.runtimeError.value = null;
    setState(() => _remountKey++);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.runtimeError,
      builder: (context, _) {
        final error = widget.runtimeError.value;
        if (error == null) {
          return KeyedSubtree(
            key: ValueKey<int>(_remountKey),
            child: widget.child,
          );
        }
        final copy = FriendlyErrorCopy.random(FriendlyErrorKind.runtime);
        final l10n = AppLocalizations.of(context);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ErrorView(
              kind: FriendlyErrorKind.runtime,
              technicalDetail: kDebugMode ? error.toString() : null,
              onRetry: _retry,
              secondaryAction: OutlinedButton(
                onPressed: () => showFeedbackSheet(
                  context,
                  category: 'runtime-error',
                  errorSummary: error.toString(),
                  initialMessage: copy.message,
                ),
                child: Text(l10n.reportIssue),
              ),
            ),
          ),
        );
      },
    );
  }
}
