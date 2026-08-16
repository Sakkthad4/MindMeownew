import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/drawing_game/game_page.dart';
import 'package:flutter_test22/drawing_game/models.dart';
import 'package:flutter_test22/drawing_game/templates.dart';

void main() {
  List<StrokePoint?> drawingFromSegments(
    List<(Offset, Offset)> segments, {
    double scaleX = 500,
    double scaleY = 500,
    Offset translation = Offset.zero,
  }) {
    final drawing = <StrokePoint?>[];
    for (final segment in segments) {
      for (var i = 0; i <= 20; i++) {
        final point = Offset.lerp(segment.$1, segment.$2, i / 20)!;
        drawing.add(
          StrokePoint(
            p: Offset(point.dx * scaleX, point.dy * scaleY) + translation,
            eraser: false,
          ),
        );
      }
      drawing.add(null);
    }
    return drawing;
  }

  test('gives a high score to the complete template', () {
    final score = GeometryScorer.score(
      userDrawing: drawingFromSegments(segmentsFor(TemplateId.cube)),
      template: TemplateId.cube,
      tolerance: 0.085,
    );

    expect(score, greaterThan(95));
  });

  test('is invariant to uniform scale and translation', () {
    final score = GeometryScorer.score(
      userDrawing: drawingFromSegments(
        segmentsFor(TemplateId.house),
        scaleX: 280,
        scaleY: 280,
        translation: const Offset(130, 75),
      ),
      template: TemplateId.house,
      tolerance: 0.085,
    );

    expect(score, greaterThan(95));
  });

  test('is not affected by input point frequency', () {
    final segments = segmentsFor(TemplateId.bridge);
    final dense = GeometryScorer.score(
      userDrawing: drawingFromSegments(segments),
      template: TemplateId.bridge,
      tolerance: 0.085,
    );
    final sparseDrawing = <StrokePoint?>[];
    for (final segment in segments) {
      sparseDrawing
        ..add(StrokePoint(p: segment.$1 * 500, eraser: false))
        ..add(StrokePoint(p: segment.$2 * 500, eraser: false))
        ..add(null);
    }
    final sparse = GeometryScorer.score(
      userDrawing: sparseDrawing,
      template: TemplateId.bridge,
      tolerance: 0.085,
    );

    expect((dense - sparse).abs(), lessThan(1));
  });

  test('penalizes an incomplete drawing', () {
    final template = segmentsFor(TemplateId.cube);
    final score = GeometryScorer.score(
      userDrawing: drawingFromSegments(template.take(3).toList()),
      template: TemplateId.cube,
      tolerance: 0.085,
    );

    expect(score, lessThan(65));
  });

  test('penalizes distorted aspect ratio', () {
    final score = GeometryScorer.score(
      userDrawing: drawingFromSegments(
        segmentsFor(TemplateId.pyramid),
        scaleX: 500,
        scaleY: 100,
      ),
      template: TemplateId.pyramid,
      tolerance: 0.085,
    );

    expect(score, lessThan(75));
  });

  test('ignores eraser input', () {
    final score = GeometryScorer.score(
      userDrawing: [
        StrokePoint(p: const Offset(10, 10), eraser: true),
        StrokePoint(p: const Offset(100, 100), eraser: true),
      ],
      template: TemplateId.cube,
      tolerance: 0.085,
    );

    expect(score, 0);
  });
}
