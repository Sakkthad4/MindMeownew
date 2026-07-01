class AppInitService {
  static Future<void> initAll() async {
    await Future.wait([
      _initCamera(),
      _initAudio(),
      _loadAIModel(),
      _fetchUserData(),
    ]);
  }

  static Future<void> _initCamera() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  static Future<void> _initAudio() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  static Future<void> _loadAIModel() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  static Future<void> _fetchUserData() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }
}
