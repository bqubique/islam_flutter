/// Prayer time calculation methods supported by the Aladhan API.
///
/// The numeric [id] is the value sent as the `method` query parameter.
/// See https://aladhan.com/calculation-methods for descriptions.
enum CalculationMethod {
  /// Shia Ithna-Ashari, Leva Institute, Qum.
  jafari(0),

  /// University of Islamic Sciences, Karachi.
  karachi(1),

  /// Islamic Society of North America (ISNA).
  isna(2),

  /// Muslim World League (default).
  muslimWorldLeague(3),

  /// Umm Al-Qura University, Makkah.
  ummAlQura(4),

  /// Egyptian General Authority of Survey.
  egypt(5),

  /// Institute of Geophysics, University of Tehran.
  tehran(7),

  /// Gulf Region.
  gulf(8),

  /// Kuwait.
  kuwait(9),

  /// Qatar.
  qatar(10),

  /// Majlis Ugama Islam Singapura, Singapore.
  singapore(11),

  /// Union Organization Islamic de France.
  france(12),

  /// Diyanet İşleri Başkanlığı, Turkey.
  turkey(13),

  /// Spiritual Administration of Muslims of Russia.
  russia(14),

  /// Moonsighting Committee Worldwide.
  moonsightingCommittee(15),

  /// Dubai (unofficial).
  dubai(16),

  /// Jabatan Kemajuan Islam Malaysia (JAKIM).
  jakimMalaysia(17),

  /// Tunisia.
  tunisia(18),

  /// Algeria.
  algeria(19),

  /// KEMENAG - Kementerian Agama Republik Indonesia.
  kemenagIndonesia(20),

  /// Morocco.
  morocco(21),

  /// Comunidade Islamica de Lisboa.
  portugal(22),

  /// Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan.
  jordan(23);

  const CalculationMethod(this.id);

  /// The `method` query parameter value for the Aladhan API.
  final int id;
}
