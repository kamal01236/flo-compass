import 'pwa_install_stub.dart'
    if (dart.library.html) 'pwa_install_web.dart'
    as impl;

void initPwaInstallCapture() => impl.initPwaInstallCapture();

bool get isInstallPromptAvailable => impl.isInstallPromptAvailable;

Future<bool> triggerInstallPrompt() => impl.triggerInstallPrompt();
