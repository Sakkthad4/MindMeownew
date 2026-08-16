import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/drawing_game/difficulty_page.dart';
import 'package:flutter_test22/drawing_game/templates.dart';

void main() {
  test('each drawing template belongs to exactly one difficulty', () {
    final configs = DrawingDifficulty.values.map(configFor).toList();
    final allTemplates = configs.expand((config) => config.pool).toList();

    expect(allTemplates.toSet(), TemplateId.values.toSet());
    expect(allTemplates.length, TemplateId.values.length);
  });

  test('hard mode gives more time and less assistance', () {
    final easy = configFor(DrawingDifficulty.easy);
    final normal = configFor(DrawingDifficulty.normal);
    final hard = configFor(DrawingDifficulty.hard);

    expect(easy.showGhostGuide, isTrue);
    expect(normal.showGhostGuide, isFalse);
    expect(hard.showGrid, isFalse);
    expect(easy.tolerance, greaterThan(normal.tolerance));
    expect(normal.tolerance, greaterThan(hard.tolerance));
    expect(hard.seconds, greaterThanOrEqualTo(normal.seconds));
  });
}
