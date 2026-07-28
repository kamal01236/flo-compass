import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/features/qr/qr_url_builder.dart';

void main() {
  const origin = 'http://localhost:8080';

  test('session URL uses /session/:id path', () {
    expect(
      QrUrlBuilder.sessionUrl('s-001', origin: origin),
      'http://localhost:8080/session/s-001',
    );
  });

  test('room URL uses /map?room= query', () {
    expect(
      QrUrlBuilder.roomUrl('ven-7N1', origin: origin),
      'http://localhost:8080/map?room=ven-7N1',
    );
  });

  test('resolveOrigin returns scheme host and port', () {
    expect(
      QrUrlBuilder.resolveOrigin(Uri.parse('https://flo.example.com/path')),
      'https://flo.example.com',
    );
    expect(
      QrUrlBuilder.resolveOrigin(
        Uri.parse('http://localhost:8080/session/s-001'),
      ),
      'http://localhost:8080',
    );
  });

  test('connect URL uses /connect/:token path', () {
    expect(
      QrUrlBuilder.connectUrl('abc123', origin: origin),
      'http://localhost:8080/connect/abc123',
    );
  });
}
