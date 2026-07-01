import 'package:flutter/material.dart';

enum CatEmotion { happy, sad, angry, calm }

class CatState extends ChangeNotifier {
  int xp = 0;
  CatEmotion emotion = CatEmotion.calm;

  bool gameActive = true; // ⭐ เพิ่มตัวนี้

  void startGame() {
    gameActive = true;
    notifyListeners();
  }

  void endGame() {
    gameActive = false;
    notifyListeners();
  }

  void addXP(int value) {
    xp += value;
    notifyListeners();
  }

  void setEmotion(CatEmotion e) {
    emotion = e;
    notifyListeners();
  }
}
