import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'home_page.dart';
import 'second_page.dart';
import 'gameBox_page.dart';
import 'exersiceBox_page.dart';
import 'calendar_page.dart';
import 'mqtt_test_page.dart';
import 'mindtalk/mindtalk_page.dart';
import 'cat_paw_loading_page.dart';

import 'supermarket/difficulty_screen.dart';
import 'Dicedash/pages/difficulty_page.dart' as dicedash;
import 'cat_paw_game/cat_paw_difficulty_screen.dart';
import 'drawing_game/difficulty_page.dart';

import 'exercise_game_movenet_page.dart';

import 'chart/game_chart_page.dart';
import 'chart/chart_store.dart';

import 'data/models/game_result.dart';
import 'data/models/cat_bond.dart';
import 'cat_bond/cat_bond_store.dart';

import 'services/mqtt_service.dart';
import 'providers/cat_state.dart';

import 'route_observer.dart';

import 'game_logic.dart';
import 'services/mqtt_dispatcher.dart';

import 'touch_collector_page.dart';
import 'mqtt_touch_service.dart';

import 'audio/soundeffect.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catState = CatState();
  final dispatcher = MqttDispatcher(catState);
  initGameLogic(catState);

  await Hive.initFlutter();

  await MqttService.I.connect(onEvent: dispatcher.handle);

  final adapter = GameResultAdapter();
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter(adapter);
  }
  Hive.registerAdapter(CatBondAdapter());

  await Hive.openBox<GameResult>('results');
  await CatBondStore.init();

  await ChartStore.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

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
        '/excersices': (context) => const ExersiceMenuPage(),
        '/calendar': (context) => const CalendarPage(),

        '/supermarket': (context) => const DifficultyScreen(),
        '/dicedash': (context) => const dicedash.DifficultyPage(),
        '/catpaw': (context) => const CatPawDifficultyScreen(),
        '/drawvis': (context) => const DrawingDifficultyPage(),

        '/chart': (context) => const GameChartPage(),

        '/gemini': (context) => const MindTalkPage(),
        '/geminiloop': (context) => const MindTalkPage(),
        '/MQTT': (context) => const MqttSimplePage(),
        '/loadpg': (context) => const CatPawLoadingPage(),
      },

      navigatorObservers: [routeObserver],
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () {
              SoundFx.play(SoundFx.hello, volume: SoundFx.helloVolume);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              "START",
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
    );
  }
}
