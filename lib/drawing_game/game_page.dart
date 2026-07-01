import 'dart:async';
import 'package:flutter/material.dart';

import 'difficulty_page.dart';
import 'models.dart';
import 'templates.dart';
import 'result_page.dart';
import 'dart:math';

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

  // difficulty config
  late final DifficultyConfig cfg;
  late final TemplateId template;

  // timer
  late int time;
  Timer? timer;

  @override
  void initState() {
    super.initState();

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
    timer?.cancel();

    final score = _score();

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
    final userPts = points.whereType<StrokePoint>().map((e) => e.p).toList();

    return GeometryScorer.score(
      userPoints: userPts,
      template: template,
      tolerance: cfg.tolerance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP =================
            Expanded(
              child: Row(
                children: [_frame(_templatePanel()), _frame(_canvasPanel())],
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
    );
  }

  // ================= PANELS =================

  Widget _templatePanel() => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: TemplatePainter(template: template)),
  );

  Widget _canvasPanel() => GestureDetector(
    onPanUpdate: (d) {
      setState(() {
        points.add(StrokePoint(p: d.localPosition, eraser: eraser));
      });
    },
    onPanEnd: (_) => points.add(null),
    child: CustomPaint(
      painter: CanvasBgPainter(
        showGrid: cfg.showGrid,
        showGhost: cfg.showGhostGuide,
        template: template,
      ),
      child: CustomPaint(painter: DrawPainter(points), child: Container()),
    ),
  );

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
    child: const Text(
      "Finish",
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
    required List<Offset> userPoints,
    required TemplateId template,
    required double tolerance,
  }) {
    if (userPoints.isEmpty) return 0;

    // =========================
    // 1) Normalize user points
    // =========================
    double minX = userPoints.first.dx;
    double maxX = userPoints.first.dx;
    double minY = userPoints.first.dy;
    double maxY = userPoints.first.dy;

    for (final p in userPoints) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }

    final w = (maxX - minX).clamp(1.0, 1e9);
    final h = (maxY - minY).clamp(1.0, 1e9);

    Offset norm(Offset p) => Offset((p.dx - minX) / w, (p.dy - minY) / h);

    final normalized = userPoints.map(norm).toList();

    // =========================
    // 2) Distance to template
    // =========================
    final segs = segmentsFor(template);

    double sumDist = 0;
    for (final p in normalized) {
      double best = double.infinity;
      for (final s in segs) {
        final d = _distPointToSegment(p, s.$1, s.$2);
        if (d < best) best = d;
      }
      sumDist += best;
    }

    final avgDist = sumDist / normalized.length;

    // =========================
    // 3) Accuracy (นุ่มขึ้น)
    // =========================
    // เดิม: 1 - (avg / tolerance)
    // ใหม่: tolerance คูณ 1.6 → ไม่หักแรง
    final accuracy = (1 - (avgDist / (tolerance * 1.6))).clamp(0.0, 1.0);

    // =========================
    // 4) Completion bonus (ง่าย)
    // =========================
    final completion = (normalized.length / 180).clamp(0.4, 1.0);

    // =========================
    // 5) Final mix
    // =========================
    final finalScore = (accuracy * 0.7 + completion * 0.3) * 100;

    return finalScore.clamp(0.0, 100.0);
  }

  static double _distPointToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;

    if (ab2 == 0) return (p - a).distance;

    final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / ab2;
    final tt = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * tt, a.dy + ab.dy * tt);
    return (p - proj).distance;
  }
}
