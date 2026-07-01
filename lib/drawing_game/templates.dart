import 'dart:math';
import 'package:flutter/material.dart';
import 'difficulty_page.dart';

enum TemplateId {
  cube,
  cubeTilt,
  prism,
  stairs,
  lBlock,
  house,
  pyramid,
  cylinder,
  zigzagDepth,
  bridge,
}

class DifficultyConfig {
  final int seconds;
  final double tolerance; // ยิ่งน้อยยิ่งยาก
  final bool showGrid;
  final bool showGhostGuide;
  final List<TemplateId> pool;

  const DifficultyConfig({
    required this.seconds,
    required this.tolerance,
    required this.showGrid,
    required this.showGhostGuide,
    required this.pool,
  });
}

DifficultyConfig configFor(DrawingDifficulty d) {
  switch (d) {
    case DrawingDifficulty.easy:
      return const DifficultyConfig(
        seconds: 60,
        tolerance: 0.11,
        showGrid: true,
        showGhostGuide: true,
        pool: [
          TemplateId.cube,
          TemplateId.prism,
          TemplateId.pyramid,
          TemplateId.cylinder,
        ],
      );
    case DrawingDifficulty.normal:
      return const DifficultyConfig(
        seconds: 60,
        tolerance: 0.085,
        showGrid: true,
        showGhostGuide: false,
        pool: [
          TemplateId.cube,
          TemplateId.cubeTilt,
          TemplateId.prism,
          TemplateId.stairs,
          TemplateId.lBlock,
          TemplateId.house,
        ],
      );
    case DrawingDifficulty.hard:
      return const DifficultyConfig(
        seconds: 60,
        tolerance: 0.07,
        showGrid: false,
        showGhostGuide: false,
        pool: [
          TemplateId.cubeTilt,
          TemplateId.stairs,
          TemplateId.lBlock,
          TemplateId.house,
          TemplateId.zigzagDepth,
          TemplateId.bridge,
        ],
      );
  }
}

TemplateId pickTemplate(List<TemplateId> pool) {
  final r = Random();
  return pool[r.nextInt(pool.length)];
}

/// ====== TEMPLATE SEGMENTS (normalized 0..1) ======
List<(Offset, Offset)> segmentsFor(TemplateId id) {
  Offset n(double x, double y) => Offset(x, y);

  List<(Offset, Offset)> segs(List<Offset> pts, List<(int, int)> edges) {
    return edges.map((e) => (pts[e.$1], pts[e.$2])).toList();
  }

  switch (id) {
    case TemplateId.cube:
      final a = n(0.18, 0.28), b = n(0.70, 0.28), c = n(0.70, 0.80), d = n(0.18, 0.80);
      final e = n(0.34, 0.16), f = n(0.86, 0.16), g = n(0.86, 0.68), h = n(0.34, 0.68);
      final pts = [a,b,c,d,e,f,g,h];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,0),
        (4,5),(5,6),(6,7),(7,4),
        (0,4),(1,5),(2,6),(3,7),
      ];
      return segs(pts, edges);

    case TemplateId.cubeTilt:
      // cube เอียง: เลื่อนหน้าหลังให้เฉียงมากขึ้น
      final a = n(0.18, 0.34), b = n(0.68, 0.26), c = n(0.72, 0.78), d = n(0.20, 0.86);
      final e = n(0.36, 0.14), f = n(0.86, 0.08), g = n(0.90, 0.60), h = n(0.40, 0.66);
      final pts = [a,b,c,d,e,f,g,h];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,0),
        (4,5),(5,6),(6,7),(7,4),
        (0,4),(1,5),(2,6),(3,7),
      ];
      return segs(pts, edges);

    case TemplateId.prism:
      // ปริซึมยาว
      final a = n(0.14, 0.30), b = n(0.62, 0.30), c = n(0.62, 0.78), d = n(0.14, 0.78);
      final e = n(0.34, 0.16), f = n(0.82, 0.16), g = n(0.82, 0.64), h = n(0.34, 0.64);
      final pts = [a,b,c,d,e,f,g,h];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,0),
        (4,5),(5,6),(6,7),(7,4),
        (0,4),(1,5),(2,6),(3,7),
      ];
      return segs(pts, edges);

    case TemplateId.stairs:
      // บันได 3 ขั้น (เส้นรูปทรง)
      final pts = <Offset>[
        n(0.18,0.78), n(0.40,0.78), n(0.40,0.62), n(0.58,0.62),
        n(0.58,0.46), n(0.78,0.46), n(0.78,0.30), n(0.18,0.30),
      ];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,7),(7,0),
      ];
      return segs(pts, edges);

    case TemplateId.lBlock:
      // L shape + depth
      final front = [
        n(0.18,0.28), n(0.62,0.28), n(0.62,0.46), n(0.40,0.46),
        n(0.40,0.80), n(0.18,0.80),
      ];
      final back = front.map((p)=> Offset(p.dx+0.18, p.dy-0.14)).toList();
      final pts = [...front, ...back];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,4),(4,5),(5,0),
        (6,7),(7,8),(8,9),(9,10),(10,11),(11,6),
        (0,6),(1,7),(2,8),(3,9),(4,10),(5,11),
      ];
      return segs(pts, edges);

    case TemplateId.house:
      // กล่อง + หลังคา
      final a = n(0.20,0.42), b = n(0.68,0.42), c = n(0.68,0.82), d = n(0.20,0.82);
      final e = n(0.36,0.28), f = n(0.84,0.28), g = n(0.84,0.68), h = n(0.36,0.68);
      final roof1 = n(0.44,0.14), roof2 = n(0.92,0.14);

      final pts = [a,b,c,d,e,f,g,h, roof1, roof2];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,0),
        (4,5),(5,6),(6,7),(7,4),
        (0,4),(1,5),(2,6),(3,7),
        (4,8),(5,9),(8,9),
      ];
      return segs(pts, edges);

    case TemplateId.pyramid:
      // พีระมิด
      final base = [n(0.22,0.78), n(0.74,0.78), n(0.60,0.60), n(0.10,0.60)];
      final top = n(0.48,0.18);
      final pts = [...base, top];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,0),
        (0,4),(1,4),(2,4),(3,4),
      ];
      return segs(pts, edges);

    case TemplateId.cylinder:
      // กระบอก: วงรีบน/ล่าง + เส้นข้าง (approx ด้วยหลาย segments)
      List<Offset> oval(Offset center, double rx, double ry, int steps) {
        final out = <Offset>[];
        for (int i=0;i<steps;i++){
          final t = (2*pi*i)/steps;
          out.add(Offset(center.dx + rx*cos(t), center.dy + ry*sin(t)));
        }
        return out;
      }
      final topC = n(0.50,0.26);
      final botC = n(0.50,0.78);
      final top = oval(topC, 0.26, 0.10, 18);
      final bot = oval(botC, 0.26, 0.10, 18);
      final pts = [...top, ...bot];

      final edges = <(int,int)>[];
      for (int i=0;i<18;i++){
        edges.add((i,(i+1)%18));
        edges.add((18+i, 18+((i+1)%18)));
      }
      // sides (left/right)
      edges.add((4, 18+4));
      edges.add((13, 18+13));
      return segs(pts, edges);

    case TemplateId.zigzagDepth:
      final pts = [
        n(0.18,0.30), n(0.46,0.30), n(0.34,0.46), n(0.62,0.46),
        n(0.50,0.62), n(0.78,0.62), n(0.66,0.78), n(0.18,0.78),
      ];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,7),(7,0)
      ];
      // depth shift
      final back = pts.map((p)=> Offset(p.dx+0.14, p.dy-0.12)).toList();
      final all = [...pts, ...back];
      final edges2 = <(int,int)>[
        ...edges,
        (8,9),(9,10),(10,11),(11,12),(12,13),(13,14),(14,15),(15,8),
        (0,8),(2,10),(4,12),(6,14),
      ];
      return segs(all, edges2);

    case TemplateId.bridge:
      final pts = [
        n(0.18,0.70), n(0.32,0.70), n(0.32,0.42), n(0.68,0.42),
        n(0.68,0.70), n(0.82,0.70), n(0.82,0.82), n(0.18,0.82),
      ];
      final edges = <(int,int)>[
        (0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(6,7),(7,0),
      ];
      return segs(pts, edges);
  }
}

String templateName(TemplateId id) {
  switch (id) {
    case TemplateId.cube: return "Cube";
    case TemplateId.cubeTilt: return "Cube Tilt";
    case TemplateId.prism: return "Prism";
    case TemplateId.stairs: return "Stairs";
    case TemplateId.lBlock: return "L-Block";
    case TemplateId.house: return "House";
    case TemplateId.pyramid: return "Pyramid";
    case TemplateId.cylinder: return "Cylinder";
    case TemplateId.zigzagDepth: return "Zigzag";
    case TemplateId.bridge: return "Bridge";
  }
}
