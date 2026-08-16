import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'home_page.dart';
import 'second_page.dart';
import 'gameBox_page.dart';
import 'calendar_page.dart';
import 'mqtt_test_page.dart';
import 'mindtalk/mindtalk_page.dart';
import 'cat_paw_loading_page.dart';

import 'supermarket/difficulty_screen.dart';
import 'Dicedash/pages/difficulty_page.dart' as dicedash;
import 'cat_paw_game/cat_paw_difficulty_screen.dart';
import 'drawing_game/difficulty_page.dart';

import 'exercise_game_movenet_page.dart';

import 'healthcare/healthcare_page.dart';
import 'healthcare/data/chart_store.dart';
import 'healthcare/data/cat_bond_store.dart';
import 'healthcare/data/exercise_session_store.dart';
import 'healthcare/data/mindtalk_emotion_store.dart';
import 'healthcare/models/exercise_session.dart';
import 'healthcare/models/game_result.dart';
import 'healthcare/models/cat_bond.dart';
import 'healthcare/models/mindtalk_emotion_event.dart';

import 'services/mqtt_service.dart';
import 'providers/cat_state.dart';

import 'route_observer.dart';

import 'game_logic.dart';
import 'services/mqtt_dispatcher.dart';

import 'touch_collector_page.dart';
import 'audio/soundeffect.dart';
import 'app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catState = CatState();
  final dispatcher = MqttDispatcher(catState);
  initGameLogic(catState);

  await Hive.initFlutter();
  await AppLanguageController.load();

  await MqttService.I.connect(onEvent: dispatcher.handle);

  final adapter = GameResultAdapter();
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CatBondAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(MindTalkEmotionEventAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ExerciseSessionAdapter());
  }

  await Hive.openBox<GameResult>('results');
  await CatBondStore.init();
  await MindTalkEmotionStore.init();
  await ExerciseSessionStore.init();

  await ChartStore.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.current,
      builder: (context, language, _) {
        return MaterialApp(
          key: ValueKey(language.code),
          debugShowCheckedModeBanner: false,
          locale: language.locale,

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),

          initialRoute: '/start',

          routes: {
            '/start': (context) => const StartPage(),
            '/home': (context) => const HomePage(),
            '/second': (context) => const SecondPage(),

            '/games': (context) => const GameMenuPage(),
            '/stretch': (context) => const MindExercisesPage(),
            '/calendar': (context) => const CalendarPage(),

            '/supermarket': (context) => const DifficultyScreen(),
            '/dicedash': (context) => const dicedash.DifficultyPage(),
            '/catpaw': (context) => const CatPawDifficultyScreen(),
            '/drawvis': (context) => const DrawingDifficultyPage(),

            '/healthcare': (context) => const HealthcarePage(),

            '/gemini': (context) => const MindTalkPage(),
            '/geminiloop': (context) => const MindTalkPage(),
            '/MQTT': (context) => const MqttSimplePage(),
            '/loadpg': (context) => const CatPawLoadingPage(),
          },

          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 425,
                color: Colors.orange,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/MindMeow.png',
                    width: 900,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 65,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  SoundFx.play(SoundFx.hello, volume: SoundFx.helloVolume);
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text(
                  AppText.get('start'),
                  style: GoogleFonts.montserrat(
                    fontSize: 70,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ),
              TouchCollectorPage(
                brokerHost: '192.168.1.10',
                clientId: 'flutter-touch-collector-01',
                onAddXp: (xp) async {
                  await CatBondStore().addXp(amount: xp, source: 'touch');
                },
              ),
            ],
          ),
          Positioned(top: 28, right: 32, child: _LanguagePicker()),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLanguage>(
      tooltip: AppText.get('chooseLanguage'),
      initialValue: AppLanguageController.current.value,
      onSelected: AppLanguageController.change,
      itemBuilder: (context) => AppLanguage.values
          .map(
            (language) => PopupMenuItem<AppLanguage>(
              value: language,
              child: Row(
                children: [
                  if (language == AppLanguageController.current.value)
                    const Icon(Icons.check, color: Colors.orange)
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 12),
                  Text(language.label, style: const TextStyle(fontSize: 26)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.orange, size: 34),
            const SizedBox(width: 10),
            Text(
              AppLanguageController.current.value.label,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 32),
          ],
        ),
      ),
    );
  }
}
