import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/word_entry.dart';
import '../../../core/services/audio_service.dart';
import '../../study/application/study_session_controller.dart';
import '../../study/presentation/quiz_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(studySessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('學測英文單字卡'),
        actions: [
          IconButton(
            tooltip: '隨機抽考',
            onPressed: () => context.pushNamed(QuizPage.routeName),
            icon: const Icon(Icons.quiz_outlined),
          ),
        ],
      ),
      body: session.when(
        data: (state) {
          if (!state.hasData) {
            return const _EmptyState();
          }
          return _StudyContent(state: state);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: '載入單字資料失敗，請稍後再試。',
          onRetry: () => ref.refresh(studySessionControllerProvider.future),
        ),
      ),
    );
  }
}

class _StudyContent extends ConsumerWidget {
  const _StudyContent({required this.state});

  final StudySessionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = state.currentWord;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LevelFilter(ref: ref),
          const SizedBox(height: 16),
          _OverviewChips(state: state),
          const SizedBox(height: 24),
          Expanded(
            child: _WordCard(
              word: word,
              showTranslation: state.showTranslation,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => _speak(ref, word.word),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('播放發音'),
              ),
              FilledButton.icon(
                onPressed: state.showTranslation
                    ? () => ref
                        .read(studySessionControllerProvider.notifier)
                        .moveToNextWord(incrementReviewed: true)
                    : () => ref.read(studySessionControllerProvider.notifier).revealTranslation(),
                icon: const Icon(Icons.translate),
                label: Text(state.showTranslation ? '下一題' : '顯示中文'),
              ),
              FilledButton.icon(
                onPressed: () => ref.read(studySessionControllerProvider.notifier).markMastered(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('標記已掌握'),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(studySessionControllerProvider.notifier).markRetryLater(),
                icon: const Icon(Icons.refresh),
                label: const Text('稍後再複習'),
              ),
              OutlinedButton.icon(
                onPressed: () => _launchCambridge(context, word),
                icon: const Icon(Icons.open_in_new),
                label: const Text('查劍橋字典'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '例句：${word.exampleEn}',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            word.exampleZh,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _speak(WidgetRef ref, String word) async {
    final audio = ref.read(wordAudioServiceProvider);
    await audio.speak(word);
  }

  Future<void> _launchCambridge(BuildContext context, WordEntry word) async {
    final url = Uri.parse(word.cambridgeUrl);
    final success = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法開啟劍橋字典連結')),
      );
    }
  }
}

class _OverviewChips extends StatelessWidget {
  const _OverviewChips({required this.state});

  final StudySessionState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      children: [
        Chip(
          label: Text('已掌握：${state.masteredCount}'),
          avatar: Icon(Icons.star_rounded, color: colorScheme.primary),
        ),
        Chip(
          label: Text('今日已複習：${state.reviewedCount}'),
          avatar: Icon(Icons.fact_check_outlined, color: colorScheme.primary),
        ),
        Chip(
          label: Text('總單字數：${state.totalWords}'),
          avatar: Icon(Icons.library_books_outlined, color: colorScheme.primary),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.showTranslation,
  });

  final WordEntry word;
  final bool showTranslation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              word.word,
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              word.partOfSpeech,
              style: textTheme.titleMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: showTranslation
                  ? Column(
                      key: const ValueKey('translation'),
                      children: [
                        Text(
                          word.translation,
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('hint'),
                      children: [
                        Icon(Icons.visibility_off_outlined, color: Colors.black26, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          '點選「顯示中文」查看釋義',
                          style: textTheme.bodyLarge?.copyWith(color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, size: 56, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            '目前沒有可用的單字資料。\n請稍後再試或匯入新的單字清單。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LevelFilter extends ConsumerStatefulWidget {
  const _LevelFilter({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_LevelFilter> createState() => _LevelFilterState();
}

class _LevelFilterState extends ConsumerState<_LevelFilter> {
  int? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(wordRepositoryProvider);
    final availableLevels = repository.getAvailableLevels();
    
    if (availableLevels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('全部'),
          selected: _selectedLevel == null,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedLevel = null);
              unawaited(ref.refresh(studySessionControllerProvider.future));
            }
          },
        ),
        ...availableLevels.map((level) => FilterChip(
          label: Text('第$level級'),
          selected: _selectedLevel == level,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedLevel = level);
              // TODO: 更新 study session 以使用選定的級別
            } else {
              setState(() => _selectedLevel = null);
            }
            unawaited(ref.refresh(studySessionControllerProvider.future));
          },
        )),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('重新載入'),
            ),
          ],
        ),
      ),
    );
  }
}


