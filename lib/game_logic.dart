import 'providers/cat_state.dart';
import 'audio/soundeffect.dart';

late CatState _cat;

void initGameLogic(CatState cat) {
  _cat = cat;
}

void onGameWin() {
  _cat.endGame();

  SoundFx.winFx();
}
