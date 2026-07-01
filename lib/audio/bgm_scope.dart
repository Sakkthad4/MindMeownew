import 'package:flutter/material.dart';
import 'bgm.dart';
import 'package:flutter_test22/route_observer.dart';

class BgmScope extends StatefulWidget {
  final String assetPath;
  final Widget child;

  const BgmScope({super.key, required this.assetPath, required this.child});

  @override
  State<BgmScope> createState() => _BgmScopeState();
}

class _BgmScopeState extends State<BgmScope> with RouteAware {
  @override
  void initState() {
    super.initState();
    Bgm.instance.play('audio/supermarket_bgm.mp3');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    Bgm.instance.stop(); // ออกจริง ๆ ก็ stop
    super.dispose();
  }

  // ✅ มีหน้าอื่น push ทับ -> ถือว่า “ออกจากโหมด” -> stop ทันที
  @override
  void didPushNext() {
    Bgm.instance.stop();
  }

  // ✅ ถ้ากลับมาหน้านี้อีก (pop หน้าบนออก) -> เปิดเพลงใหม่ (ถ้าไม่ mute)
  @override
  void didPopNext() {
    Bgm.instance.play(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
