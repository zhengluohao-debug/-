import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordAudioService {
  WordAudioService(this._tts) {
    _configure();
  }

  final FlutterTts _tts;

  Future<void> _configure() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String word) async {
    if (word.isEmpty) {
      return;
    }
    await _tts.stop();
    await _tts.speak(word);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}

final wordAudioServiceProvider = Provider<WordAudioService>((ref) {
  final tts = FlutterTts();
  final service = WordAudioService(tts);
  ref.onDispose(service.dispose);
  return service;
});



