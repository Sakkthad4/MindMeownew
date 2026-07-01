import 'package:flutter/material.dart';
import 'models.dart';

class DrawingResultPage extends StatelessWidget {
  const DrawingResultPage({
    super.key,
    required this.accuracy,
    required this.userPoints,
    required this.templateName,
  });

  final double accuracy;
  final List<StrokePoint?> userPoints;
  final String templateName;

  static const orange = Color(0xFFFF9800);
  static const green = Color(0xFF7ED957);
  static const gray = Color(0xFF666666);

  String get resultLabel {
    if (accuracy >= 90) return "Excellent";
    if (accuracy >= 70) return "Great";
    if (accuracy >= 50) return "Keep Going";
    return "Try Again";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text(
                  "Result",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // -------- LEFT : PREVIEW --------
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: orange, width: 6),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Your Drawing",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: gray,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CustomPaint(
                                  painter: _DrawPreviewPainter(
                                    points: userPoints,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // -------- RIGHT : SCORE --------
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: orange, width: 6),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Accuracy",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: gray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              templateName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: gray,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // BIG SCORE
                            Text(
                              "${accuracy.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 86,
                                fontWeight: FontWeight.w900,
                                color: green,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(
                              resultLabel,
                              style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= BUTTONS =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: "Play Again",
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _actionButton(
                      label: "Back",
                      onTap: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
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

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//                          DRAW PREVIEW PAINTER
// ============================================================================

class _DrawPreviewPainter extends CustomPainter {
  _DrawPreviewPainter({required this.points});
  final List<StrokePoint?> points;

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final pen = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a == null || b == null) continue;
      if (a.eraser) continue; // preview ไม่โชว์เส้นลบ
      canvas.drawLine(a.p, b.p, pen);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
