/// Juristic school used to compute the Asr prayer time.
///
/// The [id] is the value sent as the `school` query parameter to Aladhan.
enum Madhab {
  /// Shafi'i, Maliki, Hanbali (default). Asr shadow ratio 1.
  shafi(0),

  /// Hanafi. Asr shadow ratio 2.
  hanafi(1);

  const Madhab(this.id);

  /// The `school` query parameter value for the Aladhan API.
  final int id;
}
