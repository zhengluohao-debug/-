import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/word_entry.dart';
import '../../../core/repositories/word_repository.dart';
import '../../../core/services/progress_service.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepository();
});

final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

final studySessionControllerProvider = AsyncNotifierProvider<StudySessionController, StudySessionState>(
  StudySessionController.new,
);

class StudySessionController extends AsyncNotifier<StudySessionState> {
  final _random = Random();
  late List<WordEntry> _words;
  late Set<String> _masteredWords;

  @override
  Future<StudySessionState> build() async {
    final repository = ref.read(wordRepositoryProvider);
    _words = await repository.loadWords();

    final progress = ref.read(progressServiceProvider);
    _masteredWords = await progress.loadMasteredWords();

    if (_words.isEmpty) {
      return StudySessionState.empty();
    }

    return StudySessionState(
      currentWord: _randomWord(),
      showTranslation: false,
      reviewedCount: 0,
      masteredCount: _masteredWords.length,
      totalWords: _words.length,
      masteredWordIds: _masteredWords,
    );
  }

  void revealTranslation() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(showTranslation: true),
    );
  }

  Future<void> markMastered() async {
    final current = state.valueOrNull;
    final word = current?.currentWord;
    if (current == null || word == null) {
      return;
    }

    _masteredWords = {..._masteredWords, word.word};
    state = AsyncData(
      current.copyWith(
        masteredCount: _masteredWords.length,
        masteredWordIds: _masteredWords,
      ),
    );
    await ref.read(progressServiceProvider).updateMasteredWords(_masteredWords);
    await ref.read(progressServiceProvider).recordReview(word.word);

    moveToNextWord(incrementReviewed: true);
  }

  Future<void> markRetryLater() async {
    final current = state.valueOrNull;
    final word = current?.currentWord;
    if (current == null || word == null) {
      return;
    }

    await ref.read(progressServiceProvider).recordReview(word.word);
    moveToNextWord(incrementReviewed: true);
  }

  void moveToNextWord({bool incrementReviewed = false}) {
    final current = state.valueOrNull;
    if (current == null || _words.isEmpty) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        currentWord: _randomWord(),
        showTranslation: false,
        reviewedCount: incrementReviewed ? current.reviewedCount + 1 : current.reviewedCount,
      ),
    );
  }

  Future<void> resetMastered() async {
    _masteredWords = <String>{};
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        masteredCount: 0,
        masteredWordIds: _masteredWords,
      ),
    );
    await ref.read(progressServiceProvider).updateMasteredWords(_masteredWords);
  }

  WordEntry _randomWord() {
    if (_words.isEmpty) {
      return const WordEntry(
        word: '',
        translation: '',
        partOfSpeech: '',
        exampleEn: '',
        exampleZh: '',
        cambridgeUrl: '',
        level: 1,
      );
    }
    return _words[_random.nextInt(_words.length)];
  }
}

class StudySessionState {
  const StudySessionState({
    required this.currentWord,
    required this.showTranslation,
    required this.reviewedCount,
    required this.masteredCount,
    required this.totalWords,
    required this.masteredWordIds,
  });

  factory StudySessionState.empty() => StudySessionState(
        currentWord: const WordEntry(
          word: '',
          translation: '',
          partOfSpeech: '',
          exampleEn: '',
          exampleZh: '',
          cambridgeUrl: '',
          level: 1,
        ),
        showTranslation: false,
        reviewedCount: 0,
        masteredCount: 0,
        totalWords: 0,
        masteredWordIds: const <String>{},
      );

  final WordEntry currentWord;
  final bool showTranslation;
  final int reviewedCount;
  final int masteredCount;
  final int totalWords;
  final Set<String> masteredWordIds;

  bool get hasData => totalWords > 0 && currentWord.word.isNotEmpty;

  StudySessionState copyWith({
    WordEntry? currentWord,
    bool? showTranslation,
    int? reviewedCount,
    int? masteredCount,
    int? totalWords,
    Set<String>? masteredWordIds,
  }) {
    return StudySessionState(
      currentWord: currentWord ?? this.currentWord,
      showTranslation: showTranslation ?? this.showTranslation,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      masteredCount: masteredCount ?? this.masteredCount,
      totalWords: totalWords ?? this.totalWords,
      masteredWordIds: masteredWordIds ?? this.masteredWordIds,
    );
  }
}


