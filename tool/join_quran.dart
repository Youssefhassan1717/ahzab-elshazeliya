import 'dart:convert';
import 'dart:io';

/// Joins Qur'anic blocks that were marked separately but read as one passage,
/// including the case where a single ayah between them was never matched.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final quran = _load();
  final byName = <String, int>{};
  quran.forEach((n, s) => byName[s.name] = n);

  final target = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');
  final file = File(target.isEmpty ? 'lib/data/ahzab_data.dart' : target);
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final qPattern = RegExp('\u00A7Q\u00A7([^|]*)\\|(.*?)\u00A7Q\u00A7', dotAll: true);

  var joined = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var c = blocks[b].group(1)!;
    var changed = true;
    while (changed) {
      changed = false;
      final found = qPattern.allMatches(c).toList();
      for (var i = 0; i + 1 < found.length; i++) {
        final a = _parseRef(found[i].group(1)!);
        final z = _parseRef(found[i + 1].group(1)!);
        if (a == null || z == null || a.name != z.name) continue;
        final surah = byName[a.name];
        if (surah == null) continue;

        final between = c.substring(found[i].end, found[i + 1].start);
        final gap = z.from - a.to;
        if (gap < 1 || gap > 2) continue;

        final leftover = between
            .replaceAll(RegExp(r'\{[^}]*\}'), '')
            .replaceAll(RegExp('[\u06DE\\s]'), '');
        if (gap == 1) {
          if (leftover.isNotEmpty) continue;
        } else {
          if (!_isAyah(between, quran[surah]!.ayat[a.to + 1])) continue;
        }

        c = c.substring(0, found[i].start) +
            _block(quran, surah, a.from, z.to) +
            c.substring(found[i + 1].end);
        stdout.writeln('[${ids[b]}] joined ${a.name} '
            '${_digits(a.from)} - ${_digits(z.to)}');
        joined++;
        changed = true;
        break;
      }
    }
    text = text.substring(0, blocks[b].start) +
        "content: r'''$c'''" +
        text.substring(blocks[b].end);
  }

  if (apply) file.writeAsStringSync(text);
  stdout.writeln('joined: $joined${apply ? " - applied" : " - dry run"}');
}

/// True when the loose text between two blocks is the ayah that belongs there.
bool _isAyah(String between, String? ayah) {
  if (ayah == null) return false;
  final a = _words(between), b = _words(ayah);
  if (a.isEmpty || (a.length - b.length).abs() > 1) return false;
  var hit = 0;
  for (final w in a) {
    if (b.any((x) => _sameWord(w, x))) hit++;
  }
  return hit / b.length >= 0.7;
}

List<String> _words(String s) => RegExp('[\u0621-\u065F\u0670\u06D6-\u06ED]+')
    .allMatches(s)
    .map((m) => _norm(m.group(0)!))
    .where((w) => w.isNotEmpty)
    .toList();

bool _sameWord(String a, String b) {
  if (a == b) return true;
  final shortest = a.length < b.length ? a.length : b.length;
  if (shortest < 3 || (a.length - b.length).abs() > 2) return false;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  final row = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    row[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = prev[j - 1] + cost;
      if (prev[j] + 1 < v) v = prev[j] + 1;
      if (row[j - 1] + 1 < v) v = row[j - 1] + 1;
      row[j] = v;
    }
    prev = List<int>.from(row);
  }
  return prev[b.length] <= 2;
}

({String name, int from, int to})? _parseRef(String ref) {
  final parts = ref.split(':');
  if (parts.length != 2) return null;
  final nums = RegExp('[\u0660-\u0669]+')
      .allMatches(parts[1])
      .map((m) => _plain(m.group(0)!))
      .toList();
  if (nums.isEmpty) return null;
  return (name: parts[0].trim(), from: nums.first, to: nums.last);
}

int _plain(String arabic) => int.parse(
    arabic.runes.map((r) => (r - 0x0660).toString()).join());

String _block(Map<int, _Surah> quran, int surah, int from, int to) {
  final s = quran[surah]!;
  final buf = StringBuffer();
  for (var a = from; a <= to; a++) {
    if (buf.isNotEmpty) buf.write(' ');
    buf.write(s.ayat[a]!);
    buf.write(' ${_digits(a)}');
  }
  final ref = from == to
      ? '${s.name}: ${_digits(from)}'
      : '${s.name}: ${_digits(from)} - ${_digits(to)}';
  return '\u00A7Q\u00A7$ref|$buf\u00A7Q\u00A7';
}

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
