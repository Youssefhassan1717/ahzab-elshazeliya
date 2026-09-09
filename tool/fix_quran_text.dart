import 'dart:convert';
import 'dart:io';

/// Rewrites the text of every marked passage straight from the mushaf, so no
/// Qur'anic word is ever left as something typed by hand.
///
/// The run is located by comparing letters only, then the exact mushaf words
/// for that run are written back, ayah numbers included where a verse ends.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final target = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');
  final path = target.isEmpty ? 'lib/data/ahzab_data.dart' : target;

  final quran = _load();
  final byName = <String, int>{};
  quran.forEach((n, s) => byName[s.name] = n);

  final file = File(path);
  var text = file.readAsStringSync();
  var fixed = 0, kept = 0, failed = 0;

  text = text.replaceAllMapped(
      RegExp('\u00A7Q\u00A7([^|]*)\\|(.*?)\u00A7Q\u00A7', dotAll: true), (m) {
    final ref = m.group(1)!.trim();
    final body = m.group(2)!.trim();
    final parts = ref.split(':');
    final surah = byName[parts[0].trim()];
    if (surah == null) {
      stdout.writeln('UNKNOWN SURA  $ref');
      failed++;
      return m.group(0)!;
    }
    final nums = RegExp('[\u0660-\u0669]+')
        .allMatches(parts[1])
        .map((x) => _plain(x.group(0)!))
        .toList();

    // Every word of the referenced ayat, each tagged with the ayah it ends.
    final words = <String>[];
    final ends = <int, int>{};
    for (var a = nums.first; a <= nums.last; a++) {
      final ayah = quran[surah]!.ayat[a];
      if (ayah == null) {
        stdout.writeln('NO AYAH  $ref');
        failed++;
        return m.group(0)!;
      }
      words.addAll(ayah.split(' '));
      ends[words.length - 1] = a;
    }

    final got = body
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !_isNumber(w))
        .map(_norm)
        .toList();
    final loose = words.map(_norm).toList();

    final at = _find(got, loose);
    if (at < 0) {
      stdout.writeln('CANNOT ALIGN  $ref\n   $body');
      failed++;
      return m.group(0)!;
    }

    final out = StringBuffer();
    for (var i = at; i < at + got.length; i++) {
      if (out.isNotEmpty) out.write(' ');
      out.write(words[i]);
      // The number belongs only where the quotation runs to the ayah's end.
      if (ends.containsKey(i)) out.write(' ${_digits(ends[i]!)}');
    }
    final rebuilt = out.toString();
    if (rebuilt == body) {
      kept++;
      return m.group(0)!;
    }
    fixed++;
    stdout.writeln('rewritten  $ref');
    return '\u00A7Q\u00A7$ref|$rebuilt\u00A7Q\u00A7';
  });

  if (apply) file.writeAsStringSync(text);
  stdout.writeln('\nrewritten $fixed, already right $kept, could not align '
      '$failed${apply ? " - applied" : " - dry run"}');
  if (failed > 0) exitCode = 1;
}

/// Index where [got] appears as a consecutive run in [words], or -1.
int _find(List<String> got, List<String> words) {
  if (got.isEmpty || got.length > words.length) return -1;
  for (var i = 0; i + got.length <= words.length; i++) {
    var ok = true;
    for (var j = 0; j < got.length; j++) {
      if (words[i + j] != got[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

bool _isNumber(String w) => RegExp('^[\u0660-\u0669]+\$').hasMatch(w);

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
    .replaceAll('\u0624', '\u0648')
    .replaceAll('\u0626', '\u064A')
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
