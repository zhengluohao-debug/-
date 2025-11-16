import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/quiz_controller.dart';

class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  static const routeName = 'quiz';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('隨機抽考'),
      ),
      body: quizState.when(
        data: (state) {
          if (!state.hasQuestion) {
            return const _QuizEmptyState();
          }
          return _QuizContent(state: state);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _QuizErrorState(
          onRetry: () => ref.refresh(quizControllerProvider.future),
        ),
      ),
    );
  }
}

class _QuizContent extends ConsumerWidget {
  const _QuizContent({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Chip(
                label: Text('第 ${state.questionNumber} 題'),
                avatar: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: const Icon(Icons.help_outline, size: 18),
                ),
              ),
              Chip(
                label: Text('累計答對：${state.correctTally}'),
                avatar: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: const Icon(Icons.stars_rounded, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.question.word,
                    style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.question.partOfSpeech,
                    style: textTheme.titleMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '請選擇正確的中文意思',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final option = state.options[index];
                final isSelected = state.selectedOption == option;
                final isCorrect = state.correctAnswer == option;
                final showResult = state.answered;

                Color? background;
                Color borderColor = Colors.black12;
                Color textColor = Colors.black87;

                if (showResult) {
                  if (isCorrect) {
                    background = colorScheme.primaryContainer;
                    borderColor = colorScheme.primary;
                    textColor = colorScheme.onPrimaryContainer;
                  } else if (isSelected) {
                    background = Colors.red.shade100;
                    borderColor = Colors.redAccent;
                    textColor = Colors.red.shade900;
                  }
                } else if (isSelected) {
                  borderColor = colorScheme.primary;
                  background = colorScheme.primary.withValues(alpha: 0.1);
                  textColor = colorScheme.primary;
                }

                return OutlinedButton(
                  onPressed: showResult
                      ? null
                      : () => ref.read(quizControllerProvider.notifier).selectOption(option),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: background,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      option,
                      style: textTheme.titleMedium?.copyWith(color: textColor),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: state.options.length,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.answered
                ? Column(
                    key: const ValueKey('result'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        state.selectedOption == state.correctAnswer
                            ? '答對了！'
                            : '答錯了，正確答案：${state.correctAnswer}',
                        style: textTheme.titleMedium?.copyWith(
                          color: state.selectedOption == state.correctAnswer
                              ? colorScheme.primary
                              : Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.read(quizControllerProvider.notifier).goToNext(),
                        child: const Text('下一題'),
                      ),
                    ],
                  )
                : FilledButton.tonal(
                    key: const ValueKey('hint'),
                    onPressed: null,
                    child: const Text('作答後顯示結果'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuizEmptyState extends StatelessWidget {
  const _QuizEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 48, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            '可用單字數量太少，無法進行抽考。\n請先匯入更多單字。',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuizErrorState extends StatelessWidget {
  const _QuizErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('載入測驗題目失敗'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('重新載入'),
          ),
        ],
      ),
    );
  }
}


