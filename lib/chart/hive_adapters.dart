import 'package:hive/hive.dart';
import '../data/models/game_result.dart';

class ChartHiveAdapters {
  static void registerIfNeeded() {
    final adapter = GameResultAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
