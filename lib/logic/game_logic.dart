import '../providers/cat_state.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame(); // ⭐⭐ สำคัญมาก

  playMp3("assets/effects/game_win.mp3");
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
