import 'package:flutter/material.dart';

class DiceDashScope extends InheritedWidget {
  final ValueNotifier<bool> largeText;

  const DiceDashScope({
    super.key,
    required this.largeText,
    required super.child,
  });

  // ✅ fallback กันพัง ถ้าไม่ได้ครอบ DiceDashShell
  static final ValueNotifier<bool> _fallbackLargeText = ValueNotifier<bool>(
    true,
  );

  /// ใช้ตัวนี้แทน of(context)
  static ValueNotifier<bool> largeTextOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiceDashScope>();
    return scope?.largeText ?? _fallbackLargeText;
  }

  @override
  bool updateShouldNotify(DiceDashScope oldWidget) =>
      oldWidget.largeText != largeText;
}

class DiceDashShell extends StatefulWidget {
  final Widget child;
  const DiceDashShell({super.key, required this.child});

  @override
  State<DiceDashShell> createState() => _DiceDashShellState();
}

class _DiceDashShellState extends State<DiceDashShell> {
  final ValueNotifier<bool> largeText = ValueNotifier<bool>(true);

  @override
  void dispose() {
    largeText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiceDashScope(
      largeText: largeText,
      child: ValueListenableBuilder<bool>(
        valueListenable: largeText,
        builder: (context, isLarge, _) {
          final base = MediaQuery.of(context);
          final scaler = TextScaler.linear(isLarge ? 1.25 : 1.0);
          return MediaQuery(
            data: base.copyWith(textScaler: scaler),
            child: widget.child,
          );
        },
      ),
    );
  }
}
