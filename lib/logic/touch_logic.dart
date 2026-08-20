import '../providers/cat_state.dart';

void handleEspEvent(Map<String, dynamic> data, CatState cat) {
  if (data['type'] == 'touch' && data['touched'] == true) {
    cat.addXP(data['xp'] ?? 1);
    playMp3('cat_touch.mp3');
  }
}

void playMp3(String name) {
  print("▶ PLAY $name");
}
