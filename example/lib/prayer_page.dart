import 'package:flutter/material.dart';
import 'package:islam_flutter/islam_flutter.dart';

/// Demonstrates [PrayerService]: city-based lookup + method / madhab
/// selection + a per-call cache override.
///
/// The service instance is kept alive for the widget's lifetime so its
/// in-memory cache accumulates entries as you browse. Toggle "Force refresh"
/// to bypass the cache for the next lookup.
class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final _prayer = PrayerService(
    policy: const CachePolicy(ttl: Duration(hours: 12)),
  );

  final _cityCtrl = TextEditingController(text: 'Istanbul');
  final _countryCtrl = TextEditingController(text: 'Turkey');

  DateTime _date = DateTime.now();
  CalculationMethod _method = CalculationMethod.turkey;
  Madhab _madhab = Madhab.shafi;
  bool _forceRefresh = false;

  PrayerTimings? _timings;
  bool _loading = false;
  String? _error;
  bool _lastFromCache = false;

  @override
  void dispose() {
    _prayer.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _timings = null;
    });
    final started = DateTime.now();
    try {
      final result = await _prayer.getTimingsByCity(
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        date: _date,
        method: _method,
        madhab: _madhab,
        policy: _forceRefresh ? CachePolicy.disabled : null,
      );
      final elapsed = DateTime.now().difference(started);
      setState(() {
        _timings = result;
        _loading = false;
        // Round-trip < 50ms is almost certainly a cache hit.
        _lastFromCache = !_forceRefresh && elapsed.inMilliseconds < 50;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _clearCache() async {
    await _prayer.clearCache();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prayer cache cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        backgroundColor: cs.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear cache',
            onPressed: _clearCache,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildForm(cs),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            SelectableText(
              _error!,
              style: TextStyle(color: cs.error),
              textAlign: TextAlign.center,
            ),
          if (_timings != null) _buildResult(cs, _timings!),
        ],
      ),
    );
  }

  Widget _buildForm(ColorScheme cs) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_rounded, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _countryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.public_rounded, size: 18),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      '${_date.year}-'
                      '${_date.month.toString().padLeft(2, '0')}-'
                      '${_date.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: _pickDate,
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<CalculationMethod>(
              initialValue: _method,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Calculation method',
                prefixIcon: Icon(Icons.calculate_rounded, size: 18),
                border: OutlineInputBorder(),
              ),
              items: CalculationMethod.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _method = v);
              },
            ),
            DropdownButtonFormField<Madhab>(
              initialValue: _madhab,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Madhab (Asr school)',
                prefixIcon: Icon(Icons.balance_rounded, size: 18),
                border: OutlineInputBorder(),
              ),
              items: Madhab.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _madhab = v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Force refresh (bypass cache)'),
              subtitle: const Text(
                'Passes CachePolicy.disabled for this call only.',
              ),
              value: _forceRefresh,
              onChanged: (v) => setState(() => _forceRefresh = v),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _fetch,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Fetch prayer times'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ColorScheme cs, PrayerTimings t) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Icon(Icons.mosque_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Timings — ${t.hijriDate}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_lastFromCache)
                  Chip(
                    label: const Text('cache hit'),
                    backgroundColor: cs.secondaryContainer,
                    labelStyle: TextStyle(color: cs.onSecondaryContainer),
                  ),
              ],
            ),
            Text('Timezone: ${t.timezone}',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const Divider(),
            _row('Fajr', t.fajr),
            _row('Sunrise', t.sunrise),
            _row('Dhuhr', t.dhuhr),
            _row('Asr', t.asr),
            _row('Maghrib', t.maghrib),
            _row('Isha', t.isha),
            const Divider(),
            _row('Imsak', t.imsak),
            _row('Midnight', t.midnight),
            _row('Last third', t.lastThird),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ],
        ),
      );
}
