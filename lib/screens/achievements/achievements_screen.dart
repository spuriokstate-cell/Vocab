import 'package:flutter/material.dart';

import '../../models/progress.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';

/// Stars, badges and word counts. Celebrates effort, never compares children.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final badges = app.badgeStatus();
    final earned = badges.where((b) => b.earned).length;
    final mastered = app.wordsAt(MasteryLevel.mastered).length;
    final learned = app.profile.words.values.where((w) => w.learned).length;
    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.purple, AppColors.pink]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(children: [
                    const Mascot(mood: MascotMood.cheer, size: 96),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${app.profile.avatar} ${app.profile.name}',
                            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800)),
                        Text('⭐ ${app.profile.stars} stars',
                            style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w900)),
                        Text('$learned words learned · $mastered mastered · $earned badges',
                            style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('Badges', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, box) {
                  final cols = box.maxWidth > 700 ? 4 : box.maxWidth > 460 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    children: [
                      for (final b in badges)
                        Semantics(
                          label: '${b.badge.title}. ${b.badge.description}. '
                              '${b.earned ? 'Earned' : '${b.current} of ${b.badge.target}'}',
                          excludeSemantics: true,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: b.earned ? Colors.white : const Color(0xFFF0EDF5),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: b.earned ? AppColors.sunny : Colors.transparent, width: 3),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Opacity(
                                  opacity: b.earned ? 1 : 0.35,
                                  child: Text(b.badge.emoji, style: const TextStyle(fontSize: 46)),
                                ),
                                const SizedBox(height: 6),
                                Text(b.badge.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(b.badge.description,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.soft)),
                                const SizedBox(height: 8),
                                if (!b.earned)
                                  SoftProgressBar(value: b.fraction, height: 8, color: AppColors.sunny)
                                else
                                  const Text('Earned! 🎉',
                                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.right)),
                              ],
                            ),
                          ),
                        ),
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
