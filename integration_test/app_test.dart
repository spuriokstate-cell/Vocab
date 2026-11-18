// Runs on a real device, emulator or Windows PC:
//   flutter test integration_test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_ishtika/data/profile_store.dart';
import 'package:vocab_ishtika/data/vocabulary_repository.dart';
import 'package:vocab_ishtika/main.dart';
import 'package:vocab_ishtika/services/speech_service.dart';
import 'package:vocab_ishtika/state/app_state.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Look, Flip & Write from the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final vocab = await VocabularyRepository.loadFromAssets();
    expect(vocab.all.length, 1165);
    final app = AppState(
        vocab: vocab, store: await ProfileStore.open(), speech: SilentSpeechService());
    await app.init();
    app.settings.reducedMotion = true;
    app.settings.autoRead = false;

    await tester.pumpWidget(VocabIshtikaApp(state: app));
    await tester.pumpAndSettle();
    expect(find.text('Vocab Ishtika'), findsOneWidget);

    await tester.tap(_key('home-flipwrite'));
    await tester.pumpAndSettle();
    await tester.tap(_key('hub-flipWrite'));
    await tester.pumpAndSettle();
    await tester.tap(_key('picker-go'));
    await tester.pumpAndSettle();

    // Read the word, flip, then type it from memory.
    final word = tester.widget<Text>(_key('study-word')).data!;
    await tester.tap(_key('flip-button'));
    await tester.pumpAndSettle();
    expect(find.text(word), findsNothing);
    await tester.enterText(_key('write-box'), word);
    await tester.tap(_key('check-button'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Excellent!'), findsOneWidget);
    await tester.tap(_key('next-button'));
    await tester.pumpAndSettle();
    await tester.tap(_key('continue-button'));
    await tester.pumpAndSettle();
    expect(app.profile.words.values.where((w) => w.correct > 0).length, 1);
  });
}
