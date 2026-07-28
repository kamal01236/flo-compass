import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.navigator.onLine')
external bool get _navigatorOnLine;

@JS('window')
external JSObject get _window;

class ConnectivityPlatform {
  ConnectivityPlatform._();

  static final StreamController<bool> _controller =
      StreamController<bool>.broadcast(
        onListen: _attachListeners,
        onCancel: _detachListeners,
      );

  static int _subscriberCount = 0;
  static JSFunction? _onOnline;
  static JSFunction? _onOffline;

  static bool get isOnline => _navigatorOnLine;

  static Stream<bool> get onlineStream => _controller.stream;

  static void _attachListeners() {
    _subscriberCount++;
    _controller.add(isOnline);
    if (_subscriberCount != 1) return;

    _onOnline = ((JSAny _) => _controller.add(true)).toJS;
    _onOffline = ((JSAny _) => _controller.add(false)).toJS;
    _window.callMethod('addEventListener'.toJS, 'online'.toJS, _onOnline!);
    _window.callMethod('addEventListener'.toJS, 'offline'.toJS, _onOffline!);
  }

  static void _detachListeners() {
    _subscriberCount--;
    if (_subscriberCount > 0) return;

    if (_onOnline != null) {
      _window.callMethod('removeEventListener'.toJS, 'online'.toJS, _onOnline!);
      _onOnline = null;
    }
    if (_onOffline != null) {
      _window.callMethod(
        'removeEventListener'.toJS,
        'offline'.toJS,
        _onOffline!,
      );
      _onOffline = null;
    }
  }
}
