import '../../data/models/networking_card.dart';

String buildVCard(NetworkingCardPayload card) {
  final buffer = StringBuffer()
    ..writeln('BEGIN:VCARD')
    ..writeln('VERSION:3.0')
    ..writeln('FN:${_escape(card.displayName)}');
  if (card.jobTitle != null) {
    buffer.writeln('TITLE:${_escape(card.jobTitle!)}');
  }
  if (card.company != null) {
    buffer.writeln('ORG:${_escape(card.company!)}');
  }
  if (card.email != null) {
    buffer.writeln('EMAIL;TYPE=INTERNET:${_escape(card.email!)}');
  }
  if (card.linkedInUrl != null) {
    buffer.writeln('URL:${_escape(card.linkedInUrl!)}');
  }
  buffer.writeln('END:VCARD');
  return buffer.toString();
}

String _escape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll('\r', '\\r')
    .replaceAll('\n', '\\n')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,');
