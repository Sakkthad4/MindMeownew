import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_page.dart';
import 'app_init_service.dart';

class CatPawLoadingPage extends StatefulWidget {
  const CatPawLoadingPage({super.key});

  @override
  State<CatPawLoadingPage> createState() => _CatPawLoadingPageState();
}

class _CatPawLoadingPageState extends State<CatPawLoadingPage> {
  @override
  void initState() {
    super.initState();
    _startInit();
  }

  Future<void> _startInit() async {
    await AppInitService.initAll();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/cat_paw_loading.json',
              width: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'กำลังเตรียมความพร้อม...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
