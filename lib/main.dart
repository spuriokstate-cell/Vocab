import 'package:flutter/material.dart';

import 'data/profile_store.dart';
import 'data/vocabulary_repository.dart';
import 'screens/home/home_screen.dart';
import 'services/speech_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vocab = await VocabularyRepository.loadFromAssets();
  final problems = vocab.validate();
  if (problems.isNotEmpty) {
    debugPrint('Vocabulary problems found:\n${problems.join('\n')}');
  }
  final state = AppState(
    vocab: vocab,
    store: await ProfileStore.open(),
    speech: DeviceSpeechService(),
  );
  await state.init();
  runApp(VocabIshtikaApp(state: state));
}

class VocabIshtikaApp extends StatefulWidget {
  const VocabIshtikaApp({super.key, required this.state});
  final AppState state;

  @override
  State<VocabIshtikaApp> createState() => _VocabIshtikaAppState();
}

class _VocabIshtikaAppState extends State<VocabIshtikaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Save right away when the app goes to the background or closes.
    if (s == AppLifecycleState.paused ||
        s == AppLifecycleState.inactive ||
        s == AppLifecycleState.detached) {
      widget.state.saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: Builder(builder: (context) {
        final reduce = AppScope.of(context).settings.reducedMotion;
        return MaterialApp(
          title: 'Vocab Ishtika',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: reduce || mq.disableAnimations),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const HomeScreen(),
        );
      }),
    );
  }
}
