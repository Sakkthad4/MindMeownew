enum Difficulty { easy, normal, hard }

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case Difficulty.easy:
        return '2 ลูกเต๋า • + - • ไม่ติดลบ';
      case Difficulty.normal:
        return '2 ลูกเต๋า • + - ×';
      case Difficulty.hard:
        return '2 ลูกเต๋า • + - × ÷ • หารลงตัว';
    }
  }

  List<String> get operators {
    switch (this) {
      case Difficulty.easy:
        return ['+', '-'];
      case Difficulty.normal:
        return ['+', '-', '×'];
      case Difficulty.hard:
        return ['+', '-', '×', '÷'];
    }
  }
}

class DiceQuestion {
  final Difficulty difficulty;
  final int a;
  final int b;
  final String op;
  final int answer;
  final List<int> choices; // length 4

  const DiceQuestion({
    required this.difficulty,
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
    required this.choices,
  });

  String get expression => '$a $op $b';
}

class RoundResult {
  final int roundIndex; // 1..5
  final DiceQuestion question;
  final int selected;
  final bool isCorrect;

  const RoundResult({
    required this.roundIndex,
    required this.question,
    required this.selected,
    required this.isCorrect,
  });
}
