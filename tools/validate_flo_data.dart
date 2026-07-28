import 'dart:io';

/// CI-friendly Flo 2026 dataset validator (wraps validate_dataset.dart rules).
Future<void> main(List<String> args) async {
  final result = await Process.run('dart', [
    'run',
    'tools/validate_dataset.dart',
  ], runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
  stdout.writeln('validate_flo_data: OK');
}
