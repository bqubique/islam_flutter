enum TafseerEnum {
  jalalayn(
    'en-al-jalalayn',
    'Tafsir Al-Jalalayn',
    'Jalal ad-Din al-Mahalli & as-Suyuti',
    'english',
  ),
  ibnKathir(
    'en-tafisr-ibn-kathir',
    'Tafsir Ibn Kathir (abridged)',
    'Hafiz Ibn Kathir',
    'english',
  ),
  qushayri(
    'en-al-qushairi-tafsir',
    'Al-Qushairi Tafsir',
    'Al-Qushairi',
    'english',
  ),
  tabari(
    'ar-tafsir-al-tabari',
    'تفسير الطبري',
    'Ibn Jarir al-Tabari',
    'arabic',
  ),
  qurtubi('ar-tafsir-al-qurtubi', 'تفسير القرطبي', 'Al-Qurtubi', 'arabic'),
  saddi(
    'ar-tafsir-al-saddi',
    'تفسير السعدي',
    'Abd ar-Rahman al-Saddi',
    'arabic',
  ),
  ibnKathirUrdu(
    'ur-tafseer-ibn-e-kaseer',
    'تفسیر ابن کثیر',
    'Hafiz Ibn Kathir (Urdu)',
    'urdu',
  ),
  fathulMajid(
    'bn-tafisr-fathul-majid',
    'তাফসীর ফাতহুল মাজিদ',
    'AbdulRahman Bin Hasan Al-Alshaikh',
    'bengali',
  );
  // Add remaining editions up to 28 following the same pattern.
  // Full slug list: https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/editions.json

  const TafseerEnum(this.slug, this.name, this.author, this.language);

  /// Edition slug — matches [edition_slug] in the tafseers table.
  final String slug;

  /// Human-readable tafseer name.
  final String name;

  /// Author / translator name.
  final String author;

  /// Language of this tafseer edition.
  final String language;

  /// Look up a [TafseerEnum] by its [slug].
  /// Returns null if not found.
  static TafseerEnum? fromSlug(String slug) {
    for (final t in values) {
      if (t.slug == slug) return t;
    }
    return null;
  }

  /// All English tafseers.
  static List<TafseerEnum> get englishEditions =>
      values.where((t) => t.language == 'english').toList();

  /// All Arabic tafseers.
  static List<TafseerEnum> get arabicEditions =>
      values.where((t) => t.language == 'arabic').toList();
}
