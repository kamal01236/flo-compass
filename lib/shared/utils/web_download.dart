import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart'
    as impl;

void downloadPng(List<int> bytes, String filename) {
  impl.downloadPng(bytes, filename);
}

void downloadText(
  String text,
  String filename, {
  String mimeType = 'text/plain',
}) {
  impl.downloadText(text, filename, mimeType: mimeType);
}
