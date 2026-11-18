import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/progress.dart';
import '../../services/session_builder.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../session/session_runner.dart';
import '../session/word_picker.dart';

/// One game on a hub screen.
class HubGame {
  const HubGame(this.type, this.description, this.color, {this.mixed = false});
  final ActivityType type;
  final String description;
  final Color color;

  /// When true, runs the mixed quiz instead of a single activity type.
  final bool mixed;
}

/// A menu of games (Spelling Games, Listening Games, Word Games,
/// Look Flip & Write modes).
class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.games,
    this.skillTag = 'mixed',
  });

  final String title;
  final String intro;
  final List<HubGame> games;
  final String skillTag;

  static Future<void> play(BuildContext context, HubGame g, {String skillTag = 'mixed'}) async {
    final isFill = g.type == ActivityType.fillChoice ||
        g.type == ActivityType.fillDrag ||
        g.type == ActivityType.fillType;
    final pick = await showWordPicker(
      context,
      title: g.mixed ? 'Mixed Quiz' : g.type.label,
      showLevel: isFill || g.mixed,
      filter: g.mixed ? null : (e) => SessionBuilder.supports(g.type, e),
    );
    if (pick == null || !context.mounted) return;
    final app = AppScope.read(context);
    final b = SessionBuilder(random: app.rng);
    final items = g.mixed
        ? b.masteryQuiz(pick.words, fillLevel: pick.level)
        : isFill
            ? b.single(SessionBuilder.fillTypeForLevel(pick.level), pick.words)
            : b.single(g.type, pick.words);
    await SessionRunner.open(context,
        title: g.mixed ? 'Mixed Quiz' : g.type.label,
        items: items,
        skillTag: g.mixed ? 'quiz' : g.type.skill.name,
        color: g.color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MascotSays(intro, size: 80),
                const SizedBox(height: 18),
                LayoutBuilder(builder: (context, box) {
                  final cols = box.maxWidth > 640 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: cols == 2 ? 2.6 : 3.2,
                    children: [
                      for (final g in games)
                        _GameCard(game: g, onTap: () => play(context, g, skillTag: skillTag)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});
  final HubGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: game.color,
      borderRadius: BorderRadius.circular(26),
      elevation: 2,
      child: InkWell(
        key: ValueKey('hub-${game.mixed ? 'mixed' : game.type.name}'),
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Text(game.mixed ? '🎲' : game.type.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.mixed ? 'Mixed Quiz' : game.type.label,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(game.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- hub configs

const lookFlipWriteGames = [
  HubGame(ActivityType.flipWrite, 'See the word, flip the card, write it from memory', AppColors.purple),
  HubGame(ActivityType.listenWrite, 'Hear the word and write it, no peeking!', AppColors.sky),
  HubGame(ActivityType.memoryWrite, 'Study the word, the card flips by itself', AppColors.pink),
];

const spellingGames = [
  HubGame(ActivityType.spelling, 'Listen to the word and spell it', AppColors.coral),
  HubGame(ActivityType.scramble, 'Put the mixed-up letters in order', AppColors.mint),
  HubGame(ActivityType.flipWrite, 'Look, flip and write the word', AppColors.purple),
  HubGame(ActivityType.memoryWrite, 'Remember the word, then write it', AppColors.pink),
];

const listeningGames = [
  HubGame(ActivityType.listenChoose, 'Hear a word and tap the one you heard', AppColors.sky),
  HubGame(ActivityType.listenWrite, 'Hear a word and write it', AppColors.purple),
  HubGame(ActivityType.spelling, 'Listen to the word in a sentence and spell it', AppColors.coral),
];

const wordGames = [
  HubGame(ActivityType.wordToMeaning, 'Pick what the word means', AppColors.mint),
  HubGame(ActivityType.meaningToWord, 'Read the meaning, find the word', AppColors.coral),
  HubGame(ActivityType.picture, 'Match the picture to its word', AppColors.sunny),
  HubGame(ActivityType.fillChoice, 'Find the missing word in a sentence', AppColors.purple),
  HubGame(ActivityType.flipWrite, 'Every kind of question mixed together', AppColors.pink, mixed: true),
];

/// Daily Practice: a short mixed session picked by the smart review system.
class DailyPracticeScreen extends StatelessWidget {
  const DailyPracticeScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final app = AppScope.read(context);
    final s = app.settings;
    final words = app.scheduler.daily(app.vocab.grade(s.grade), app.profile, s.dailyGoal);
    final items = SessionBuilder(random: app.rng).mixed(words, [
      ActivityType.flipWrite,
      SessionBuilder.fillTypeForLevel(s.fillLevel),
      ActivityType.wordToMeaning,
      ActivityType.listenChoose,
      ActivityType.spelling,
      ActivityType.scramble,
    ]);
    await SessionRunner.open(context,
        title: 'Daily Practice', items: items, skillTag: 'daily', color: AppColors.leaf);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    final today = app.practicedToday;
    final goalMet = today >= s.dailyGoal;
    final needs = app.wordsAt(MasteryLevel.needsPractice, grade: s.grade).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Practice')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ContentWidth(
            maxWidth: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Mascot(mood: goalMet ? MascotMood.cheer : MascotMood.happy, size: 150)),
                const SizedBox(height: 12),
                Text(
                  goalMet ? 'You reached today\'s goal! 🎉' : 'Practice a few words today!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                SoftProgressBar(
                  value: s.dailyGoal == 0 ? 1 : today / s.dailyGoal,
                  color: AppColors.leaf,
                  height: 18,
                  semanticLabel: 'Daily goal',
                ),
                const SizedBox(height: 6),
                Text('$today of ${s.dailyGoal} questions today',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  needs > 0
                      ? 'Ishi picked $needs tricky word${needs == 1 ? '' : 's'} to practice, plus words to review and new words.'
                      : 'Ishi picks words to review and new words for you.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, color: AppColors.soft),
                ),
                const SizedBox(height: 24),
                BigButton(
                  key: const ValueKey('daily-start'),
                  label: goalMet ? 'Practice more' : 'Start today\'s practice',
                  emoji: '🚀',
                  color: AppColors.leaf,
                  onPressed: () => _start(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
