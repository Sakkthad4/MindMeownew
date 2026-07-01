import 'dart:math';
import 'models.dart';

class DiceDashEngine {
  final Random _rng = Random();

  int _rollDie() => _rng.nextInt(6) + 1;

  DiceQuestion generateQuestion(Difficulty difficulty) {
    final ops = difficulty.operators;
    final op = ops[_rng.nextInt(ops.length)];

    int a = _rollDie();
    int b = _rollDie();

    if (op == '-') {
      if (difficulty == Difficulty.easy && b > a) {
        final tmp = a;
        a = b;
        b = tmp;
      }
    }

    if (op == '÷') {
      b = _rng.nextInt(5) + 2; // 2..6
      final k = _rng.nextInt(3) + 1; // 1..3
      a = b * k; // 2..18
    }

    final ans = _compute(a, b, op);

    final choices = _makeChoicesGuaranteed(
      correct: ans,
      a: a,
      b: b,
      op: op,
      difficulty: difficulty,
    );

    return DiceQuestion(
      difficulty: difficulty,
      a: a,
      b: b,
      op: op,
      answer: ans,
      choices: choices,
    );
  }

  int _compute(int a, int b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return a ~/ b;
      default:
        return a + b;
    }
  }

  List<int> _makeChoicesGuaranteed({
    required int correct,
    required int a,
    required int b,
    required String op,
    required Difficulty difficulty,
  }) {
    final wrongs = <int>{};

    bool valid(int v) {
      if (difficulty == Difficulty.easy && v < 0) return false;
      if (v < -20 || v > 120) return false;
      if (v == correct) return false;
      return true;
    }

    void tryAdd(int v) {
      if (valid(v)) wrongs.add(v);
    }

    tryAdd(correct + 1);
    tryAdd(correct - 1);
    tryAdd(correct + 2);
    tryAdd(correct - 2);
    tryAdd(correct + 3);
    tryAdd(correct - 3);

    final otherOps = ['+', '-', '×', '÷']..remove(op);
    for (final alt in otherOps) {
      if (alt == '÷') {
        if (b != 0 && a % b == 0) tryAdd(a ~/ b);
      } else {
        tryAdd(_compute(a, b, alt));
      }
    }

    int guard = 0;
    while (wrongs.length < 3 && guard < 500) {
      guard++;
      final jitter = _rng.nextInt(17) - 8;
      tryAdd(correct + jitter);
    }

    int step = 4;
    while (wrongs.length < 3 && step < 40) {
      tryAdd(correct + step);
      tryAdd(correct - step);
      step += 3;
    }

    final wrongList = wrongs.take(3).toList()..shuffle(_rng);
    final finalChoices = <int>[correct, ...wrongList]..shuffle(_rng);
    return finalChoices;
  }
}
