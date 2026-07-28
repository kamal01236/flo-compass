import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

JSObject? get _notificationCtor {
  final notification = _window.getProperty('Notification'.toJS);
  if (notification.isUndefinedOrNull) return null;
  return notification as JSObject;
}

bool get isNotificationSupported => _notificationCtor != null;

String _readPermission() {
  final ctor = _notificationCtor;
  if (ctor == null) return 'default';
  final permission = ctor.getProperty('permission'.toJS);
  if (permission.isUndefinedOrNull) return 'default';
  return (permission as JSString).toDart;
}

Future<String> requestNotificationPermission() async {
  if (!isNotificationSupported) return 'default';
  final ctor = _notificationCtor!;
  final fn = ctor.getProperty('requestPermission'.toJS);
  if (fn.isUndefinedOrNull) return 'default';
  final promise = (fn as JSFunction).callAsFunction() as JSPromise<JSString>;
  return (await promise.toDart).toDart;
}

Future<String> getNotificationPermission() async => _readPermission();

bool get isNotificationPermissionGranted =>
    isNotificationSupported && _readPermission() == 'granted';

bool get isNotificationPermissionDenied =>
    isNotificationSupported && _readPermission() == 'denied';

Future<void> showLocalNotification(
  String title,
  String body, {
  String? tag,
}) async {
  if (!isNotificationSupported || !isNotificationPermissionGranted) return;

  final navigator = _window.getProperty('navigator'.toJS);
  if (navigator.isUndefinedOrNull) return;
  final serviceWorker = (navigator as JSObject).getProperty(
    'serviceWorker'.toJS,
  );
  if (serviceWorker.isUndefinedOrNull) return;
  final ready = (serviceWorker as JSObject).getProperty('ready'.toJS);
  if (ready.isUndefinedOrNull) return;

  final registration = await (ready as JSPromise<JSObject>).toDart;
  final options =
      <String, JSAny?>{
            'body': body.toJS,
            if (tag != null) 'tag': tag.toJS,
          }.jsify()
          as JSObject;
  registration.callMethod('showNotification'.toJS, title.toJS, options);
}
