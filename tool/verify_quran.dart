import 'dart:convert';
import 'dart:io';

/// Checks every marked passage against the mushaf: the text must either be the
/// referenced ayat in full, or a run of words taken from them.
/// Usage: dart run tool/verify_quran.dart [--file=path]
void main(List<String> args) {
  final target = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');
  final path = target.isEmpty ? 'lib/data/ahzab_data.dart' : target;

  final quran = _load();
  final byName = <String, int>{};
  quran.forEach((n, s) => byName[_key(s.name)] = n);

  final text = File(path).readAsStringSync();
  var checked = 0, exact = 0, partial = 0, bad = 0;

  for (final m in RegExp('\u00A7Q\u00A7([^|]*)\\|(.*?)\u00A7Q\u00A7', dotAll: true)
      .allMatches(text)) {
    checked++;
    final ref = m.group(1)!.trim();
    final body = m.group(2)!.trim();
    final parts = ref.split(':');
    final surah = byName[_key(parts[0])];
    if (surah == null) {
      stdout.writeln('UNKNOWN SURA  $ref');
      bad++;
      continue;
    }
    final nums = RegExp('[\u0660-\u0669]+')
        .allMatches(parts[1])
        .map((x) => _plain(x.group(0)!))
        .toList();
    final from = nums.first, to = nums.last;

    final full = StringBuffer();
    final words = <String>[];
    for (var a = from; a <= to; a++) {
      final ayah = quran[surah]!.ayat[a];
      if (ayah == null) {
        stdout.writeln('NO AYAH  $ref');
        bad++;
        break;
      }
      if (full.isNotEmpty) full.write(' ');
      full.write('$ayah ${_digits(a)}');
      words.addAll(ayah.split(' '));
    }

    if (body == full.toString()) {
      exact++;
      continue;
    }
    // A fragment: its words must appear in order inside the referenced ayat.
    final got = body.split(RegExp(r'\s+')).where((w) => !_isNumber(w)).toList();
    if (_isRun(got, words)) {
      partial++;
      stdout.writeln('partial   $ref  ${got.length} of ${words.length} words');
      continue;
    }
    bad++;
    stdout.writeln('MISMATCH  $ref');
    stdout.writeln('   book: $body');
    stdout.writeln('  mushaf: $full');
  }

  stdout.writeln('\nchecked $checked, exact $exact, partial $partial, '
      'wrong $bad');
  if (bad > 0) exitCode = 1;
}

bool _isNumber(String w) => RegExp('^[\u0660-\u0669]+\$').hasMatch(w);

/// Sura names are spelt with and without the maddah, so ignore it when looking
/// one up.
String _key(String name) =>
    name.trim().replaceAll(RegExp('[\u0653\u0654\u0655]'), '');

/// True when [got] appears as a consecutive run inside [words].
bool _isRun(List<String> got, List<String> words) {
  if (got.isEmpty || got.length > words.length) return false;
  for (var i = 0; i + got.length <= words.length; i++) {
    var ok = true;
    for (var j = 0; j < got.length; j++) {
      if (words[i + j] != got[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

int _plain(String arabic) =>
    int.parse(arabic.runes.map((r) => (r - 0x0660).toString()).join());

Map<int, _Surah> _load() {
  final raw = jsonDecode(File('tool/quran.json').readAsStringSync()) as List;
  final out = <int, _Surah>{};
  for (final e in raw) {
    var words = (e['text'] as String).trim().split(RegExp(r'\s+'));
    if (e['ayah'] == 1 && e['surah'] != 1 && words.length > 4) {
      if (words.take(4).map(_norm).join(' ') == _basmala) words = words.sublist(4);
    }
    words = words
        .map((w) => w.replaceAll(RegExp('[\u06D6-\u06ED]'), ''))
        .where((w) => _norm(w).isNotEmpty)
        .toList();
    out
        .putIfAbsent(e['surah'], () => _Surah(_surahName(e['name'])))
        .ayat[e['ayah']] = words.join(' ');
  }
  return out;
}

class _Surah {
  final String name;
  final ayat = <int, String>{};
  _Surah(this.name);
}

final _diacritics = RegExp('[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]');
final _basmala = '\u0628\u0633\u0645 \u0627\u0644\u0644\u0647 '
    '\u0627\u0644\u0631\u062D\u0645\u0646 \u0627\u0644\u0631\u062D\u064A\u0645';

String _norm(String s) => s
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[\u0623\u0625\u0622\u0671]'), '\u0627')
    .replaceAll('\u0649', '\u064A')
    .replaceAll('\u0629', '\u0647')
    .replaceAll('\u0621', '');

String _surahName(String raw) {
  final parts = raw.trim().split(RegExp(r'\s+'));
  if (parts.length > 1 && _norm(parts.first) == '\u0633\u0648\u0631\u0647') {
    parts.removeAt(0);
  }
  return parts
      .join(' ')
      .replaceAll(RegExp('[\u064B-\u0652\u0670\u0640\u06D6-\u06ED]'), '')
      .replaceAll('\u0671', '\u0627')
      .replaceAll(RegExp('\u0625\$'), '\u0623');
}

String _digits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();
