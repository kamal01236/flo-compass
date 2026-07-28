import 'dart:async';

class ConnectivityPlatform {
  ConnectivityPlatform._();

  static bool get isOnline => true;

  static Stream<bool> get onlineStream => Stream<bool>.value(true);
}
