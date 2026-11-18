import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../achievements/achievements_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../games/game_hub_screen.dart';
import '../grades/grade_map_screen.dart';
import '../parents/parent_gate.dart';
import '../session/word_picker.dart';

/// The colorful home screen with big buttons for every activity.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _flashcards(BuildContext context) async {
    final pick = await showWordPicker(context, title: 'Flashcards', counts: const [10, 20, 0]);
    if (pick == null || !context.mounted) return;
    _push(context, FlashcardsScreen(words: pick.words));
  }

  Future<void> _fillBlanks(BuildContext context) => GameHubScreen.play(
      context, const HubGame(ActivityType.fillChoice, '', AppColors.sky));

  void _switchChild(BuildContext context) {
    final app = AppScope.read(context);
    if (app.profiles.length < 2) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Who is learning?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final p in app.profiles)
            ListTile(
              leading: Text(p.avatar, style: const TextStyle(fontSize: 34)),
              title: Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              trailing: p.id == app.profile.id ? const Icon(Icons.check_circle, color: AppColors.right) : null,
              onTap: () {
                app.switchProfile(p);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.profile;
    final g1 = app.gradeStats(1), g2 = app.gradeStats(2);
    final tiles = <_Tile>[
      _Tile('Grade 1 Vocabulary', '🐣', AppColors.grade1, () => _push(context, const GradeMapScreen(grade: 1)),
          id: 'grade1'),
      _Tile('Grade 2 Vocabulary', '🚀', AppColors.grade2, () => _push(context, const GradeMapScreen(grade: 2)),
          id: 'grade2'),
      _Tile('Look, Flip & Write', '🃏', AppColors.purple, () => _push(context, const GameHubScreen(
          title: 'Look, Flip & Write',
          intro: 'Look at the word, flip the card, then write it from memory!',
          games: lookFlipWriteGames,
          skillTag: 'spelling')), id: 'flipwrite'),
      _Tile('Fill in the Blanks', '🧩', AppColors.sky, () => _fillBlanks(context), id: 'fillblanks'),
      _Tile('Flashcards', '📇', AppColors.pink, () => _flashcards(context), id: 'flashcards'),
      _Tile('Spelling Games', '🐝', AppColors.coral, () => _push(context, const GameHubScreen(
          title: 'Spelling Games', intro: 'Let\'s practice spelling!', games: spellingGames,
          skillTag: 'spelling')), id: 'spelling'),
      _Tile('Listening Games', '👂', AppColors.mint, () => _push(context, const GameHubScreen(
          title: 'Listening Games', intro: 'Turn on your ears!', games: listeningGames,
          skillTag: 'listening')), id: 'listening'),
      _Tile('Word Games', '🎮', AppColors.sunny, () => _push(context, const GameHubScreen(
          title: 'Word Games', intro: 'Meanings, pictures and quizzes!', games: wordGames)),
          id: 'wordgames'),
      _Tile('Daily Practice', '📅', AppColors.leaf, () => _push(context, const DailyPracticeScreen()),
          id: 'daily'),
      _Tile('My Achievements', '🏅', AppColors.deepPurple, () => _push(context, const AchievementsScreen()),
          id: 'achievements'),
      _Tile('Parent Dashboard', '🔒', AppColors.soft, () => _push(context, const ParentGate()),
          id: 'parents'),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: 1000,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Semantics(
                          button: true,
                          label: 'Learner: ${p.name}',
                          child: GestureDetector(
                            onTap: () => _switchChild(context),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Text(p.avatar, style: const TextStyle(fontSize: 30)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Vocab Ishtika',
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.deepPurple)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Text('⭐ ${p.stars}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      MascotSays('Hi ${p.name}! Let\'s learn some words today!', size: 96),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, box) {
                        final cards = [
                          _GradeCard(grade: 1, stats: g1, onTap: () => _push(context, const GradeMapScreen(grade: 1))),
                          _GradeCard(grade: 2, stats: g2, onTap: () => _push(context, const GradeMapScreen(grade: 2))),
                        ];
                        if (box.maxWidth < 560) {
                          return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
                        }
                        return Row(children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[1]),
                        ]);
                      }),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: 1000,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: LayoutBuilder(builder: (context, box) {
                    final cols = box.maxWidth > 860 ? 4 : box.maxWidth > 560 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.15,
                      children: tiles,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade, required this.stats, required this.onTap});
  final int grade;
  final GradeStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forGrade(grade);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Grade $grade progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            SoftProgressBar(value: stats.learnedFraction, color: color, semanticLabel: 'Grade $grade progress'),
            const SizedBox(height: 8),
            Text('📘 ${stats.learned}/${stats.total} learned   🏆 ${stats.mastered} mastered',
                style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.emoji, this.color, this.onTap, {required this.id});
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.5),
      child: InkWell(
        key: ValueKey('home-$id'),
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(child: Text(emoji, style: const TextStyle(fontSize: 46))),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}
