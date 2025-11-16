import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  ProgressService();

  static const _masteredWordsKey = 'mastered_words';
  static const _reviewHistoryKey = 'review_history';

  Future<Set<String>> loadMasteredWords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_masteredWordsKey);
    return data?.toSet() ?? <String>{};
  }

  Future<void> updateMasteredWords(Set<String> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_masteredWordsKey, words.toList());
  }

  Future<void> recordReview(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_reviewHistoryKey);

    final Map<String, dynamic> history =
        historyJson != null ? json.decode(historyJson) as Map<String, dynamic> : {};

    final now = DateTime.now().toIso8601String();
    history[word] = now;

    await prefs.setString(_reviewHistoryKey, json.encode(history));
  }
}


