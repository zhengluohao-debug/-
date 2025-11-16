import 'dart:convert';

class WordEntry {
  const WordEntry({
    required this.word,
    required this.translation,
    required this.partOfSpeech,
    required this.exampleEn,
    required this.exampleZh,
    required this.cambridgeUrl,
    required this.level,
    this.audioUrl,
  });

  final String word;
  final String translation;
  final String partOfSpeech;
  final String exampleEn;
  final String exampleZh;
  final String cambridgeUrl;
  final int level; // 1-6 級
  final String? audioUrl;

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      word: json['word'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      exampleEn: json['exampleEn'] as String? ?? '',
      exampleZh: json['exampleZh'] as String? ?? '',
      cambridgeUrl: json['cambridgeUrl'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'partOfSpeech': partOfSpeech,
      'exampleEn': exampleEn,
      'exampleZh': exampleZh,
      'cambridgeUrl': cambridgeUrl,
      'level': level,
      'audioUrl': audioUrl,
    };
  }

  static List<WordEntry> decodeList(String jsonStr) {
    final rawList = json.decode(jsonStr) as List<dynamic>;
    return rawList
        .map((item) => WordEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}


