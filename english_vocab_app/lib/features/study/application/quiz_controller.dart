import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/word_entry.dart';
import 'study_session_controller.dart';

final quizControllerProvider = AsyncNotifierProvider<QuizController, QuizState>(
  QuizController.new,
);

class QuizController extends AsyncNotifier<QuizState> {
  final _random = Random();
  late List<WordEntry> _words;

  @override
  Future<QuizState> build() async {
    _words = await ref.read(wordRepositoryProvider).loadWords();

    if (_words.length < 2) {
      return QuizState.empty();
    }

    return _generateState(correctTally: 0, questionNumber: 1);
  }

  void selectOption(String option) {
    final current = state.valueOrNull;
    if (current == null || current.answered) {
      return;
    }

    final isCorrect = option == current.correctAnswer;
    state = AsyncData(
      current.copyWith(
        selectedOption: option,
        answered: true,
        correctTally: isCorrect ? current.correctTally + 1 : current.correctTally,
      ),
    );
  }

  void goToNext() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      _generateState(
        correctTally: current.correctTally,
        questionNumber: current.questionNumber + 1,
      ),
    );
  }

  QuizState _generateState({required int correctTally, required int questionNumber}) {
    final question = _words[_random.nextInt(_words.length)];
    final options = _shuffleOptions(question);
    return QuizState(
      question: question,
      options: options,
      correctAnswer: question.translation,
      selectedOption: null,
      answered: false,
      correctTally: correctTally,
      questionNumber: questionNumber,
    );
  }

  List<String> _shuffleOptions(WordEntry question) {
    final options = <String>{question.translation};
    while (options.length < 4 && options.length < _words.length) {
      final candidate = _words[_random.nextInt(_words.length)].translation;
      options.add(candidate);
    }
    final optionList = options.toList();
    optionList.shuffle(_random);
    return optionList;
  }
}

class QuizState {
  const QuizState({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
    required this.answered,
    required this.correctTally,
    required this.questionNumber,
  });

  factory QuizState.empty() => QuizState(
        question: const WordEntry(
          word: '',
          translation: '',
          partOfSpeech: '',
          exampleEn: '',
          exampleZh: '',
          cambridgeUrl: '',
          level: 1,
        ),
        options: const [],
        correctAnswer: '',
        selectedOption: null,
        answered: false,
        correctTally: 0,
        questionNumber: 0,
      );

  final WordEntry question;
  final List<String> options;
  final String correctAnswer;
  final String? selectedOption;
  final bool answered;
  final int correctTally;
  final int questionNumber;

  bool get hasQuestion => question.word.isNotEmpty;

  QuizState copyWith({
    WordEntry? question,
    List<String>? options,
    String? correctAnswer,
    String? selectedOption,
    bool? answered,
    int? correctTally,
    int? questionNumber,
  }) {
    return QuizState(
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      selectedOption: selectedOption ?? this.selectedOption,
      answered: answered ?? this.answered,
      correctTally: correctTally ?? this.correctTally,
      questionNumber: questionNumber ?? this.questionNumber,
    );
  }
}


