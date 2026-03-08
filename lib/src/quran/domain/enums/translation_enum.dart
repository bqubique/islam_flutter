enum TranslationEnum {
  english('en', 'English', 'Saheeh International'),
  french('fr', 'French', 'Muhammad Hamidullah'),
  indonesian('id', 'Indonesian', 'Ministry of Religious Affairs'),
  russian('ru', 'Russian', 'Elmir Kuliev'),
  turkish('tr', 'Turkish', 'Diyanet Isleri'),
  urdu('ur', 'Urdu', 'Abul A\'ala Maududi'),
  bengali('bn', 'Bengali', 'Muhiuddin Khan'),
  chinese('zh', 'Chinese', 'Ma Jian'),
  spanish('es', 'Spanish', 'Muhammad Isa Garcia'),
  swedish('sv', 'Swedish', 'Knut Bernström');

  const TranslationEnum(this.code, this.language, this.translator);

  final String code;

  /// Human-readable language name.
  final String language;

  /// Translator credit.
  final String translator;

  /// Look up a [TranslationEnum] by its ISO [code].
  /// Returns null if not found.
  static TranslationEnum? fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}
