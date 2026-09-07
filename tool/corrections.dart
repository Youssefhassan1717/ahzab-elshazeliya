import 'dart:convert';
import 'dart:io';

/// One-off corrections: passages the book names instead of quoting, a missing
/// separator and a misspelt word.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final quran = _load();
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final jobs = <String, List<(Pattern, String)>>{
    'lutf': [
      // The book names these three passages; the app quotes them in full.
      (
        RegExp('\\(\\s*\u0622\u064A\u0629 \u0627\u0644\u0643\u064F\u0631\u0652'
            '\u0633\u0650\u0649\u0650\u0651\\s*\\)\\s*\u06DE\\s*'
            '\u00A7Q\u00A7\u0627\u0644\u0628\u0642\u0631\u0629: [^|]*\\|.*?\u00A7Q\u00A7',
            dotAll: true),
        _block(quran, 2, 255, 257),
      ),
      (
        RegExp('\\(\\s*\u0644\u064E\u0642\u064E\u062F\u0652 .*?\\)\\s*'
            '\u0625\u0650\u0644\u064E\u0649 \u0622\u062E\u0650\u0631 '
            '\u0627\u0644\u0633\u064F\u0651\u0648\u0631\u0629',
            dotAll: true),
        _block(quran, 9, 128, 129),
      ),
      (
        RegExp('\\(\\s*\u0644\u0650\u0626\u0650\u0644\u0627\u0641\u0650 .*?\\)\\s*'
            '\u0625\u0650\u0644\u0650\u0649 \u0622\u062E\u0650\u0631\u0647\u0627',
            dotAll: true),
        _block(quran, 106, 1, 4),
      ),
    ],
    'barr': [
      (
        '\u0648\u064E\u0627\u0644\u0634\u064E\u0651\u0628\u064E\u0647\u0650',
        '\u0648\u064E\u0627\u0644\u062A\u064E\u0651\u0634\u064E\u0628\u064F\u0651\u0647\u0650',
      ),
    ],
    'bahr': [
      (
        '\u0644\u0625\u0650\u0628\u0652\u0631\u064E\u0627\u0647\u0650\u064A\u0645\u064E '
            '\u0648\u064E\u0633\u064E\u062E\u064E\u0651\u0631\u0652\u062A\u064E',
        '\u0644\u0625\u0650\u0628\u0652\u0631\u064E\u0627\u0647\u0650\u064A\u0645\u064E '
            '\u06DE \u0648\u064E\u0633\u064E\u062E\u064E\u0651\u0631\u0652\u062A\u064E',
      ),
    ],
  };

  var done = 0, missed = 0;
  for (var b = blocks.length - 1; b >= 0; b--) {
    final edits = jobs[ids[b]];
    if (edits == null) continue;
    var c = blocks[b].group(1)!;
    for (final (from, to) in edits) {
      final before = c.length;
      c = c.replaceFirst(from, to);
      if (c.length == before && !c.contains(to)) {
        stdout.writeln('MISS in ${ids[b]}: $from');
        missed++;
      } else {
        done++;
      }
    }
    text = text.substring(0, blocks[b].start) +
        "content: r'''$c'''" +
        text.substring(blocks[b].end);
  }

  if (apply) file.writeAsStringSync(text);
  stdout.writeln('applied: $done, missed: $missed'
      '${apply ? " - written" : " - dry run"}');
}

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
