import 'dart:async';
import 'package:flutter/material.dart';
import '../app_language.dart';
import '../ble/robot_celebration.dart';
import '../healthcare/data/chart_store.dart';

import 'difficulty_page.dart';
import 'models.dart';
import 'templates.dart';
import 'result_page.dart';
import 'dart:math';
import '../audio/page_voice.dart';

class DrawingGamePage extends StatefulWidget {
  const DrawingGamePage({super.key, required this.difficulty});
  final DrawingDifficulty difficulty;

  @override
  State<DrawingGamePage> createState() => _DrawingGamePageState();
}

class _DrawingGamePageState extends State<DrawingGamePage> {
  static const orange = Color(0xFFFF9800);

  // drawing
  final List<StrokePoint?> points = [];
  bool eraser = false;
  static const double _eraserRadius = 28;

  // difficulty config
  late final DifficultyConfig cfg;
  late final TemplateId template;

  // timer
  late int time;
  Timer? timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    unawaited(RobotCelebrationController.instance.greetFeature());

    cfg = configFor(widget.difficulty);
    template = pickTemplate(cfg.pool);
    time = cfg.seconds;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => time--);
      if (time <= 0) finish();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void finish() {
    if (_finished || !mounted) return;
    _finished = true;
    timer?.cancel();

    final score = _score();
    unawaited(_saveResultAndOpenSummary(score));
  }

  Future<void> _saveResultAndOpenSummary(double score) async {
    final scorePoints = score.round().clamp(0, 100);
    try {
      await ChartStore().logResult(
        game: 'drawvis',
        difficulty: widget.difficulty.name,
        accuracyPercent: score,
        hits: scorePoints,
        miss: 100 - scorePoints,
      );
    } catch (error, stackTrace) {
      debugPrint('DRAWVIS RESULT SAVE ERROR: $error\n$stackTrace');
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DrawingResultPage(
          accuracy: score,
          userPoints: points,
          templateName: templateName(template),
        ),
      ),
    );
  }

  double _score() {
    return GeometryScorer.score(
      userDrawing: points,
      template: template,
      tolerance: cfg.tolerance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageVoice(
        assetPath: VoiceAssets.letsDrawing,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/bg/drawitbg.png', fit: BoxFit.cover),
            ),
            Positioned.fill(child: ColoredBox(color: Color(0x1FFFFFFF))),
            SafeArea(
              child: Column(
                children: [
                  // ================= TOP =================
                  Expanded(
                    child: Row(
                      children: [
                        _frame(_templatePanel()),
                        _frame(_canvasPanel()),
                      ],
                    ),
                  ),

                  // ================= TOOLS =================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        _tool(Icons.edit, false),
                        _tool(Icons.auto_fix_high, true),
                        const Spacer(),
                        _timerBadge(),
                        const SizedBox(width: 14),
                        _finishButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PANELS =================

  Widget _templatePanel() => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: TemplatePainter(template: template)),
  );

  Widget _canvasPanel() => GestureDetector(
    onPanStart: (d) => _updateDrawing(d.localPosition),
    onPanUpdate: (d) {
      _updateDrawing(d.localPosition);
    },
    onPanEnd: (_) {
      if (points.isNotEmpty && points.last != null) points.add(null);
    },
    child: CustomPaint(
      painter: CanvasBgPainter(
        showGrid: cfg.showGrid,
        showGhost: cfg.showGhostGuide,
        template: template,
      ),
      child: CustomPaint(painter: DrawPainter(points), child: Container()),
    ),
  );

  void _updateDrawing(Offset position) {
    setState(() {
      if (!eraser) {
        points.add(StrokePoint(p: position, eraser: false));
        return;
      }

      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        if (point != null && (point.p - position).distance <= _eraserRadius) {
          points[i] = null;
        }
      }
      _cleanSeparators();
    });
  }

  void _cleanSeparators() {
    for (var i = points.length - 1; i > 0; i--) {
      if (points[i] == null && points[i - 1] == null) points.removeAt(i);
    }
    if (points.isNotEmpty && points.first == null) points.removeAt(0);
  }

  Widget _frame(Widget child) => Expanded(
    child: Container(
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: orange, width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    ),
  );

  // ================= TOOLS =================

  Widget _tool(IconData icon, bool erase) => IconButton(
    iconSize: 44,
    icon: Icon(icon, color: orange),
    onPressed: () => setState(() => eraser = erase),
  );

  Widget _finishButton() => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: orange,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    onPressed: finish,
    child: Text(
      AppText.get('finish'),
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    ),
  );

  Widget _timerBadge() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: orange, width: 4),
    ),
    alignment: Alignment.center,
    child: Text(
      "${time}s",
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
  );
}

// ============================================================================
//                               PAINTERS
// ============================================================================

class DrawPainter extends CustomPainter {
  DrawPainter(this.points);
  final List<StrokePoint?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a == null || b == null) continue;

      pen.color = a.eraser ? Colors.white : Colors.black;
      canvas.drawLine(a.p, b.p, pen);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class TemplatePainter extends CustomPainter {
  TemplatePainter({required this.template});
  final TemplateId template;

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFDFDFD),
    );

    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final segs = segmentsFor(template);
    Offset mapN(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    for (final s in segs) {
      canvas.drawLine(mapN(s.$1), mapN(s.$2), p);
    }
  }

  @override
  bool shouldRepaint(covariant TemplatePainter old) => old.template != template;
}

class CanvasBgPainter extends CustomPainter {
  CanvasBgPainter({
    required this.showGrid,
    required this.showGhost,
    required this.template,
  });

  final bool showGrid;
  final bool showGhost;
  final TemplateId template;

  @override
  void paint(Canvas canvas, Size size) {
    // white background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // GRID
    if (showGrid) {
      final g = Paint()
        ..color = const Color(0x11000000)
        ..strokeWidth = 1.2;

      const step = 40.0;
      for (double x = 0; x <= size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
      }
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
      }
    }

    // GHOST GUIDE
    if (showGhost) {
      final ghost = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final segs = segmentsFor(template);
      Offset mapN(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

      for (final s in segs) {
        canvas.drawLine(mapN(s.$1), mapN(s.$2), ghost);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasBgPainter old) =>
      old.showGrid != showGrid ||
      old.showGhost != showGhost ||
      old.template != template;
}

// ============================================================================
//                               SCORER
// ============================================================================

class GeometryScorer {
  static double score({
    required List<StrokePoint?> userDrawing,
    required TemplateId template,
    required double tolerance,
  }) {
    final strokes = _extractStrokes(userDrawing);
    if (strokes.isEmpty) return 0;

    final rawSegments = segmentsFor(template);
    final userBounds = _bounds(strokes.expand((stroke) => stroke));
    final templateBounds = _bounds(
      rawSegments.expand((segment) => [segment.$1, segment.$2]),
    );

    // Uniform scaling preserves the aspect ratio. The previous scorer scaled
    // X and Y independently, so a flattened shape could look "perfect".
    final normalizedStrokes = strokes
        .map(
          (stroke) =>
              stroke.map((point) => _normalize(point, userBounds)).toList(),
        )
        .toList();
    final normalizedTemplate = rawSegments
        .map(
          (segment) => (
            _normalize(segment.$1, templateBounds),
            _normalize(segment.$2, templateBounds),
          ),
        )
        .toList();

    final userSamples = _sampleStrokes(normalizedStrokes);
    final templateSamples = _sampleSegments(normalizedTemplate);
    if (userSamples.length < 6) return 0;

    final userToTemplate = _nearestDistances(userSamples, templateSamples);
    final templateToUser = _nearestDistances(templateSamples, userSamples);

    final precision = _withinTolerance(userToTemplate, tolerance);
    final coverage = _withinTolerance(templateToUser, tolerance);
    final symmetricDistance =
        (_trimmedMean(userToTemplate) + _trimmedMean(templateToUser)) / 2;
    final similarity = exp(-pow(symmetricDistance / (tolerance * 1.35), 2));

    // Both coverage and precision are required: missing edges and scribbles
    // are penalized even when some parts happen to overlap the template.
    final score =
        (similarity * 0.35 + coverage * 0.40 + precision * 0.25) * 100;
    return score.clamp(0.0, 100.0);
  }

  static List<List<Offset>> _extractStrokes(List<StrokePoint?> drawing) {
    final strokes = <List<Offset>>[];
    var current = <Offset>[];
    for (final point in drawing) {
      if (point == null || point.eraser) {
        if (current.isNotEmpty) strokes.add(current);
        current = <Offset>[];
      } else {
        current.add(point.p);
      }
    }
    if (current.isNotEmpty) strokes.add(current);
    return strokes;
  }

  static ({double minX, double minY, double size}) _bounds(
    Iterable<Offset> points,
  ) {
    final list = points.toList();
    var minX = list.first.dx;
    var maxX = list.first.dx;
    var minY = list.first.dy;
    var maxY = list.first.dy;
    for (final point in list.skip(1)) {
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }
    return (
      minX: minX,
      minY: minY,
      size: max(maxX - minX, maxY - minY).clamp(1e-6, double.infinity),
    );
  }

  static Offset _normalize(
    Offset point,
    ({double minX, double minY, double size}) bounds,
  ) {
    return Offset(
      (point.dx - bounds.minX) / bounds.size,
      (point.dy - bounds.minY) / bounds.size,
    );
  }

  static List<Offset> _sampleStrokes(List<List<Offset>> strokes) {
    final samples = <Offset>[];
    for (final stroke in strokes) {
      samples.addAll(_samplePolyline(stroke));
    }
    return samples;
  }

  static List<Offset> _samplePolyline(List<Offset> points) {
    const spacing = 0.012;
    if (points.length < 2) return points;

    final samples = <Offset>[points.first];
    var distanceUntilNextSample = spacing;
    var segmentStart = points.first;

    for (var i = 1; i < points.length; i++) {
      final segmentEnd = points[i];
      var remaining = (segmentEnd - segmentStart).distance;

      while (remaining >= distanceUntilNextSample && remaining > 0) {
        final t = distanceUntilNextSample / remaining;
        segmentStart = Offset.lerp(segmentStart, segmentEnd, t)!;
        samples.add(segmentStart);
        remaining = (segmentEnd - segmentStart).distance;
        distanceUntilNextSample = spacing;
      }

      distanceUntilNextSample -= remaining;
      segmentStart = segmentEnd;
    }
    if ((samples.last - points.last).distance > spacing * 0.25) {
      samples.add(points.last);
    }
    return samples;
  }

  static List<Offset> _sampleSegments(List<(Offset, Offset)> segments) {
    const spacing = 0.012;
    final samples = <Offset>[];
    for (final segment in segments) {
      final length = (segment.$2 - segment.$1).distance;
      final steps = max(1, (length / spacing).ceil());
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        samples.add(Offset.lerp(segment.$1, segment.$2, t)!);
      }
    }
    return samples;
  }

  static List<double> _nearestDistances(List<Offset> from, List<Offset> to) {
    return from.map((point) {
      var nearest = double.infinity;
      for (final candidate in to) {
        nearest = min(nearest, (point - candidate).distance);
      }
      return nearest;
    }).toList();
  }

  static double _withinTolerance(List<double> distances, double tolerance) {
    final count = distances.where((distance) => distance <= tolerance).length;
    return count / distances.length;
  }

  static double _trimmedMean(List<double> distances) {
    final sorted = [...distances]..sort();
    final kept = max(1, (sorted.length * 0.9).ceil());
    return sorted.take(kept).reduce((a, b) => a + b) / kept;
  }
}
