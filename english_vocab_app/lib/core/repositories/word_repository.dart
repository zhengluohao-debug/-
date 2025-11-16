import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/word_entry.dart';

class WordRepository {
  WordRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle,
        _cache = const <WordEntry>[];

  final AssetBundle _bundle;
  List<WordEntry> _cache;

  Future<List<WordEntry>> loadWords({int? level}) async {
    if (_cache.isEmpty) {
      // 先嘗試載入 words.json，如果不存在則使用 sample_words.json
      try {
        final raw = await _bundle.loadString('assets/data/words.json');
        _cache = WordEntry.decodeList(raw);
      } catch (e) {
        // 如果 words.json 不存在，使用 sample_words.json
        final raw = await _bundle.loadString('assets/data/sample_words.json');
        _cache = WordEntry.decodeList(raw);
      }
    }
    
    if (level != null) {
      return _cache.where((word) => word.level == level).toList();
    }
    
    return _cache;
  }
  
  List<int> getAvailableLevels() {
    if (_cache.isEmpty) {
      return [];
    }
    return _cache.map((w) => w.level).toSet().toList()..sort();
  }
}


