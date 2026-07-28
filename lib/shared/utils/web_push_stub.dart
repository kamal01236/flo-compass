bool get isNotificationSupported => false;

Future<String> requestNotificationPermission() async => 'default';

Future<String> getNotificationPermission() async => 'default';

bool get isNotificationPermissionGranted => false;

bool get isNotificationPermissionDenied => false;

Future<void> showLocalNotification(
  String title,
  String body, {
  String? tag,
}) async {}
