import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

void initPwaInstallCapture() {
  // pwa.js registers beforeinstallprompt; ensure the bridge is ready.
  _window.getProperty('triggerFloInstallPrompt'.toJS);
}

bool get isInstallPromptAvailable {
  final ready = _window.getProperty('floInstallPromptReady'.toJS);
  if (ready.isUndefinedOrNull) return false;
  return (ready as JSBoolean).toDart;
}

Future<bool> triggerInstallPrompt() async {
  final fn = _window.getProperty('triggerFloInstallPrompt'.toJS);
  if (fn.isUndefinedOrNull) return false;
  final promise = (fn as JSFunction).callAsFunction() as JSPromise;
  final result = await promise.toDart;
  if (result.isUndefinedOrNull) return false;
  return (result as JSBoolean).toDart;
}
