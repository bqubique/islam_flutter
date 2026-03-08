import 'package:flutter/material.dart';
import 'package:islam_flutter/islam_flutter.dart';

void main() {
  runApp(const IslamFlutterExampleApp());
}

class IslamFlutterExampleApp extends StatelessWidget {
  const IslamFlutterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DbInitGate(),
    );
  }
}

class DbInitGate extends StatefulWidget {
  const DbInitGate({super.key});

  @override
  State<DbInitGate> createState() => _DbInitGateState();
}

class _DbInitGateState extends State<DbInitGate> {
  double? _progress;
  String _status = 'Checking database…';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await QuranService().init(
        onDownloadStart: () => setState(() {
          _progress = 0;
        }),
        onProgress: (p) => setState(() => _progress = p),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: cs.primary),
              const SizedBox(height: 24),
              const Text(
                'Quran Explorer',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Icon(Icons.error_outline, color: cs.error, size: 36),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _progress = null;
                      _status = 'Checking database…';
                    });
                    _init();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ] else ...[
                Text(_status, style: TextStyle(color: cs.onSurface)),
                const SizedBox(height: 16),
                _progress == null
                    ? const LinearProgressIndicator()
                    : Column(
                        children: [
                          LinearProgressIndicator(value: _progress),
                          const SizedBox(height: 8),
                          Text(
                            '${(_progress! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _quran = QuranService();

  List<Chapter> _allChapters = [];
  bool _chaptersLoading = true;

  Chapter? _selectedChapter;
  int? _selectedVerseId;
  TranslationEnum _selectedTranslation = TranslationEnum.english;
  TafseerEnum _selectedTafseer = TafseerEnum.jalalayn;

  List<Verse>? _verses;
  VerseWithTafseer? _verseWithTafseer;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllChapters();
  }

  Future<void> _loadAllChapters() async {
    try {
      final chapters = await Future.wait(
        List.generate(114, (i) => _quran.getChapterById(i + 1)),
      );
      setState(() {
        _allChapters = chapters;
        _chaptersLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load chapters: $e';
        _chaptersLoading = false;
      });
    }
  }

  Future<void> _onChapterSelected(Chapter? chapter) async {
    if (chapter == null) return;
    setState(() {
      _selectedChapter = chapter;
      _selectedVerseId = null;
      _verses = null;
      _verseWithTafseer = null;
      _loading = true;
      _error = null;
    });
    try {
      final verses = await _quran.getVersesByChapter(
        chapter.id,
        dialect: DialectEnum.hafs,
      );
      setState(() {
        _verses = verses;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchVerse() async {
    if (_selectedChapter == null || _selectedVerseId == null) return;
    setState(() {
      _verseWithTafseer = null;
      _loading = true;
      _error = null;
    });
    try {
      final result = await _quran.getVerseWithTafseer(
        _selectedChapter!.id,
        _selectedVerseId!,
        translation: _selectedTranslation,
        tafseer: _selectedTafseer,
      );
      setState(() {
        _verseWithTafseer = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onVerseSelected(int? verseId) async {
    setState(() => _selectedVerseId = verseId);
    await _fetchVerse();
  }

  Future<void> _onTranslationChanged(TranslationEnum? val) async {
    if (val == null) return;
    setState(() => _selectedTranslation = val);
    if (_selectedVerseId != null) await _fetchVerse();
  }

  Future<void> _onTafseerChanged(TafseerEnum? val) async {
    if (val == null) return;
    setState(() => _selectedTafseer = val);
    if (_selectedVerseId != null) await _fetchVerse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Explorer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildSelectors(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    final canPickAyah = _verses != null;
    final canPickOptions = _selectedVerseId != null;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                flex: 3,
                child: _chaptersLoading
                    ? const LinearProgressIndicator()
                    : _dropdown<Chapter>(
                        label: 'Surah',
                        icon: Icons.menu_book_rounded,
                        value: _selectedChapter,
                        hint: 'Select Surah',
                        items: _allChapters
                            .map((ch) => DropdownMenuItem(
                                  value: ch,
                                  child: Text(
                                    '${ch.id}. ${ch.transliteration} — ${ch.name}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: _onChapterSelected,
                      ),
              ),
              Expanded(
                flex: 2,
                child: _dropdown<int>(
                  label: 'Ayah',
                  icon: Icons.format_list_numbered_rounded,
                  value: _selectedVerseId,
                  hint: canPickAyah ? 'Select Ayah' : '—',
                  items: canPickAyah
                      ? List.generate(_verses!.length, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text('Ayah $n'),
                              ))
                          .toList()
                      : null,
                  onChanged: _onVerseSelected,
                ),
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _dropdown<TranslationEnum>(
                  label: 'Translation',
                  icon: Icons.translate_rounded,
                  value: _selectedTranslation,
                  hint: 'Translation',
                  enabled: canPickOptions,
                  items: TranslationEnum.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.language),
                          ))
                      .toList(),
                  onChanged: _onTranslationChanged,
                ),
              ),
              Expanded(
                child: _dropdown<TafseerEnum>(
                  label: 'Tafseer',
                  icon: Icons.auto_stories_rounded,
                  value: _selectedTafseer,
                  hint: 'Tafseer',
                  enabled: canPickOptions,
                  items: TafseerEnum.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: _onTafseerChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_selectedChapter == null) {
      return const Center(
        child: Text('Select a Surah to get started.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    if (_selectedVerseId == null) {
      return _ChapterSummaryView(chapter: _selectedChapter!);
    }
    if (_verseWithTafseer == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _VerseDetailView(
      chapter: _selectedChapter!,
      verseId: _selectedVerseId!,
      translationLabel: _selectedTranslation.language,
      tafseerLabel: _selectedTafseer.name,
      data: _verseWithTafseer!,
    );
  }
}

class _ChapterSummaryView extends StatelessWidget {
  const _ChapterSummaryView({required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primary,
                      child: Text('${chapter.id}',
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chapter.transliteration,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(chapter.name,
                              style:
                                  TextStyle(fontSize: 16, color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _row('Type', chapter.type),
                _row('Total Ayahs', '${chapter.totalVerses}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Now select an Ayah from the dropdown above.',
            textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface)),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ]),
      );
}

class _VerseDetailView extends StatelessWidget {
  const _VerseDetailView({
    required this.chapter,
    required this.verseId,
    required this.translationLabel,
    required this.tafseerLabel,
    required this.data,
  });

  final Chapter chapter;
  final int verseId;
  final String translationLabel;
  final String tafseerLabel;
  final VerseWithTafseer data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Chip(
            avatar: Icon(Icons.bookmark_rounded, color: cs.onPrimary, size: 16),
            label: Text(
              '${chapter.transliteration} ${chapter.id}:$verseId',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimary),
            ),
            backgroundColor: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        _section(
          context,
          icon: Icons.text_fields_rounded,
          label: 'Arabic',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              data.text,
              style: const TextStyle(fontSize: 22, height: 2.0),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _section(
          context,
          icon: Icons.translate_rounded,
          label: 'Translation — $translationLabel',
          child: SelectableText(data.translation,
              style: const TextStyle(fontSize: 15, height: 1.7)),
        ),
        const SizedBox(height: 12),
        _section(
          context,
          icon: Icons.auto_stories_rounded,
          label: 'Tafseer — $tafseerLabel',
          child: SelectableText(
            data.tafseer,
            style: TextStyle(fontSize: 14, height: 1.8, color: cs.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext ctx,
      {required IconData icon, required String label, required Widget child}) {
    final cs = Theme.of(ctx).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(icon, size: 16, color: cs.primary),
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: cs.primary,
                      letterSpacing: 0.5,
                    )),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}
