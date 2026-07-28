import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class VoiceInputException implements Exception {
  VoiceInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<bool> isVoiceInputSupported() async {
  final recognition = _window.getProperty('webkitSpeechRecognition'.toJS);
  return !recognition.isUndefinedOrNull;
}

Future<String?> captureVoiceInput() async {
  final recognitionCtor = _window.getProperty('webkitSpeechRecognition'.toJS);
  if (recognitionCtor.isUndefinedOrNull) return null;

  final recognition =
      (recognitionCtor as JSFunction).callAsConstructor() as JSObject;
  recognition.setProperty('continuous'.toJS, false.toJS);
  recognition.setProperty('interimResults'.toJS, false.toJS);
  recognition.setProperty('maxAlternatives'.toJS, 1.toJS);

  final completer = Completer<String?>();
  var hasResult = false;

  void finish({String? text, Object? error}) {
    if (completer.isCompleted) return;
    if (error != null) {
      completer.completeError(error);
      return;
    }
    completer.complete(text);
  }

  recognition.setProperty(
    'onresult'.toJS,
    ((JSAny event) {
      hasResult = true;
      final transcript = _readTranscript(event);
      if (transcript == null || transcript.trim().isEmpty) {
        finish(error: VoiceInputException('No speech detected.'));
        return;
      }
      finish(text: transcript.trim());
    }).toJS,
  );

  recognition.setProperty(
    'onerror'.toJS,
    ((JSAny event) {
      finish(error: VoiceInputException(_messageForError(event)));
    }).toJS,
  );

  recognition.setProperty(
    'onend'.toJS,
    ((JSAny _) {
      if (!hasResult) {
        finish(error: VoiceInputException('No speech detected.'));
      }
    }).toJS,
  );

  try {
    recognition.callMethod('start'.toJS);
  } catch (_) {
    finish(error: VoiceInputException('Voice input failed. Try again.'));
  }

  return completer.future;
}

String? _readTranscript(JSAny event) {
  final eventObject = event as JSObject;
  final results = eventObject.getProperty('results'.toJS);
  if (results.isUndefinedOrNull) return null;
  final firstResult = (results as JSObject).getProperty(0.toJS);
  if (firstResult.isUndefinedOrNull) return null;
  final firstAlt = (firstResult as JSObject).getProperty(0.toJS);
  if (firstAlt.isUndefinedOrNull) return null;
  final transcript = (firstAlt as JSObject).getProperty('transcript'.toJS);
  if (transcript.isUndefinedOrNull) return null;
  return transcript.toString();
}

String _messageForError(JSAny event) {
  final eventObject = event as JSObject;
  final error = eventObject.getProperty('error'.toJS);
  if (error.isUndefinedOrNull) {
    return 'Voice input failed. Try again.';
  }
  final errorName = error.toString();
  if (errorName == 'no-speech') {
    return 'No speech detected.';
  }
  if (errorName == 'not-allowed' || errorName == 'service-not-allowed') {
    return 'Microphone permission denied.';
  }
  return 'Voice input failed. Try again.';
}
