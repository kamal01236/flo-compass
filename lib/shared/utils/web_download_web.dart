import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

void downloadPng(List<int> bytes, String filename) {
  _downloadBytes(bytes, filename, 'image/png');
}

void downloadText(
  String text,
  String filename, {
  String mimeType = 'text/plain',
}) {
  _downloadBytes(utf8.encode(text), filename, mimeType);
}

void _downloadBytes(List<int> bytes, String filename, String mimeType) {
  final blob = Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    BlobPropertyBag(type: mimeType),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
