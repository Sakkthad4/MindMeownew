import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/app_language.dart';

void main() {
  test('new game names are used in every language and statistics label', () {
    for (final language in AppLanguage.values) {
      AppLanguageController.current.value = language;

      expect(AppText.get('supermarket'), 'MindCart');
      expect(AppText.get('catPaw'), 'QuickPaw');
      expect(AppText.get('draw'), 'Drawit');
      expect(AppText.get('drawingGame'), 'Drawit');
      expect(AppText.name('supermarket'), 'MindCart');
      expect(AppText.name('catpaw'), 'QuickPaw');
      expect(AppText.name('drawvis'), 'Drawit');
    }
  });
}
