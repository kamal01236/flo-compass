class DataIntegrityException implements Exception {
  DataIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'DataIntegrityException: $message';
}
