abstract final class AssetPaths {
  static const String _pkg = 'packages/islam_flutter';

  static const String islamDb = '$_pkg/assets/islam.db';

  static const String azkar = '$_pkg/assets/azkar/azkar.json';

  static const String _hadithBase = '$_pkg/assets/hadith';

  static String hadith(String bookId, String langCode) =>
      '$_hadithBase/${bookId}_$langCode.json';
}
