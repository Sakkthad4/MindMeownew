import 'package:flutter/material.dart';


const kDiceDashOrange = Colors.orange;
const kDiceDashOrangeDark = Color(0xFFF57C00);

/// แทน withOpacity แบบไม่ deprecated
Color alphaColor(Color c, double a) {
  final v = (a * 255).round().clamp(0, 255);
  return c.withAlpha(v);
}

ThemeData diceDashTheme(BuildContext context) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Theme.of(context).brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      primary: Colors.orange,
      surface: scheme.surface,
    ),
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 30),
    ),
    textTheme: Theme.of(context).textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
      headlineMedium: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
      headlineSmall: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      titleMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      bodyLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      bodyMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      labelLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        minimumSize: const Size.fromHeight(64),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: BorderSide(color: alphaColor(Colors.orange, 0.9), width: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        minimumSize: const Size.fromHeight(64),
      ),
    ),
  );
}
