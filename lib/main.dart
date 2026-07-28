import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/observability/crash_reporter.dart';
import 'shared/widgets/shared_widgets.dart';

/// Non-fatal error patterns that should not surface via [ErrorBoundary].
bool _isNonFatalWebError(Object error) {
  final message = error.toString();
  return message.contains('ViewInsets cannot be negative') ||
      message.contains('_viewInsets.isNonNegative') ||
      message.contains('Failed to decode frame') ||
      message.contains('EncodingError');
}

Future<void> main() async {
  final runtimeError = ValueNotifier<Object?>(null);
  var handlingError = false;
  var reportScheduled = false;
  Object? pendingError;

  void flushPendingError() {
    reportScheduled = false;
    final error = pendingError;
    if (error == null || runtimeError.value == error) return;
    runtimeError.value = error;
    pendingError = null;
  }

  void reportRuntimeError(Object error) {
    if (_isNonFatalWebError(error)) {
      handlingError = false;
      return;
    }
    pendingError = error;
    if (reportScheduled) return;
    reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handlingError = false;
      flushPendingError();
    });
  }

  runZonedGuarded(
    () async {
      if (kIsWeb) {
        usePathUrlStrategy();
      }
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        if (handlingError) {
          AppLog.d('Suppressed recursive FlutterError: ${details.exception}');
          handlingError = false;
          return;
        }
        if (_isNonFatalWebError(details.exception)) {
          AppLog.d('Suppressed non-fatal web error: ${details.exception}');
          handlingError = false;
          return;
        }
        handlingError = true;
        CrashReporter.instance.recordFlutterError(details);
        FlutterError.dumpErrorToConsole(details);
        reportRuntimeError(details.exception);
      };
      final app = await buildApp();
      runApp(ErrorBoundary(runtimeError: runtimeError, child: app));
    },
    (error, stack) {
      if (handlingError) {
        AppLog.d('Suppressed recursive zone error: $error');
        handlingError = false;
        return;
      }
      if (_isNonFatalWebError(error)) {
        AppLog.d('Suppressed non-fatal web error: $error');
        handlingError = false;
        return;
      }
      handlingError = true;
      CrashReporter.instance.recordZoneError(error, stack);
      reportRuntimeError(error);
      AppLog.e('Unhandled app error', error, stack);
    },
  );
}
