import 'dart:convert';
import 'dart:io';

/// Finds Qur'anic passages inside the ahzab and marks them as
/// `§Q§reference|mushaf text§Q§` so the reader shows them in the mushaf face
/// with ayah rosettes. Pass `--apply` to write the changes.
void main(List<String> args) {
  final apply = args.contains('--apply');
  const minWords = 6;
  const gram = 4;

  final raw = jsonDecode(File('tool/quran.json').readAsStringSync()) as List;
  final surahs = <int, _Surah>{};
  for (final e in raw) {
    var words = (e['text'] as String).trim().split(RegExp(r'\s+'));
    // Every surah but al-Fatiha has the basmala glued onto its first ayah.
    if (e['ayah'] == 1 && e['surah'] != 1 && words.length > 4) {
      final head = words.take(4).map(_norm).join(' ');
      if (head == _basmala) words = words.sublist(4);
    }
    surahs
        .putIfAbsent(e['surah'], () => _Surah(e['surah'], _surahName(e['name'])))
        .add(e['ayah'], words);
  }

  final index = <String, List<_Hit>>{};
  for (final s in surahs.values) {
    for (var i = 0; i + gram <= s.norm.length; i++) {
      index
          .putIfAbsent(s.norm.sublist(i, i + gram).join(' '), () => [])
          .add(_Hit(s, i));
    }
  }

  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final report = StringBuffer();
  var marked = 0, complete = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var content = blocks[b].group(1)!;
    final tokens = _tokenise(content, _markedRegions(content));
    final spans = <_Span>[];

    var t = 0;
    while (t + gram <= tokens.length) {
      final hits = index[tokens.sublist(t, t + gram).map((x) => x.norm).join(' ')];
      if (hits == null) {
        t++;
        continue;
      }
      _Span? best;
      for (final hit in hits) {
        var ws = hit.index, ts = t;
        while (ws > 0 && ts > 0 && hit.surah.norm[ws - 1] == tokens[ts - 1].norm) {
          ws--;
          ts--;
        }
        var we = hit.index, te = t;
        while (we < hit.surah.norm.length &&
            te < tokens.length &&
            hit.surah.norm[we] == tokens[te].norm) {
          we++;
          te++;
        }
        if (te - ts < minWords) continue;
        if (best == null || te - ts > best.length) {
          best = _Span(ts, te, hit.surah, ws, we);
        }
      }
      if (best == null) {
        t++;
        continue;
      }
      spans.add(best);
      t = best.end;
    }

    if (spans.isEmpty) continue;

    for (final span in spans.reversed) {
      final s = span.surah;
      final firstAyah = s.ayahAt(span.wordStart);
      final lastAyah = s.ayahAt(span.wordEnd - 1);
      final whole = span.wordStart == s.startOf(firstAyah) &&
          span.wordEnd == s.endOf(lastAyah);
      // A partial ayah is not a quotation the reader recites as Qur'an, and it
      // cannot carry a rosette, so leave it as plain hizb text.
      if (!whole) {
        report.writeln('[${ids[b]}] skipped fragment ${s.name} '
            '${_digits(s.numberOf(firstAyah))} (${span.length} words)');
        continue;
      }

      final buf = StringBuffer();
      for (var a = firstAyah; a <= lastAyah; a++) {
        final from = a == firstAyah ? span.wordStart : s.startOf(a);
        final to = a == lastAyah ? span.wordEnd : s.endOf(a);
        if (to <= from) continue;
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(s.display.sublist(from, to).join(' '));
        if (from == s.startOf(a) && to == s.endOf(a)) {
          buf.write(' ${_digits(s.numberOf(a))}');
        }
      }

      final ref = firstAyah == lastAyah
          ? '${s.name}: ${_digits(s.numberOf(firstAyah))}'
          : '${s.name}: ${_digits(s.numberOf(firstAyah))} - '
              '${_digits(s.numberOf(lastAyah))}';

      content = content.substring(0, tokens[span.start].start) +
          '\u00A7Q\u00A7$ref|$buf\u00A7Q\u00A7' +
          content.substring(tokens[span.end - 1].end);
      marked++;
      if (whole) complete++;
      report.writeln('[${ids[b]}] $ref | complete | ${span.length} words');
    }

    text = text.substring(0, blocks[b].start) +
        "content: r'''$content'''" +
        text.substring(blocks[b].end);
  }

  File('_quran_report.txt').writeAsStringSync(report.toString());
  if (apply) file.writeAsStringSync(text);
  stdout.writeln('passages: $marked (complete: $complete, '
      'fragments: ${marked - complete})${apply ? " - applied" : " - dry run"}');
}

final _diacritics = RegExp('[\u064B-\u0652\u0670\u0640\u06D6-\u06ED]');

final _basmala = [
  '\u0628\u0633\u0645',
  '\u0627\u0644\u0644\u0647',
  '\u0627\u0644\u0631\u062D\u0645\u0646',
  '\u0627\u0644\u0631\u062D\u064A\u0645',
].join(' ');

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
  return parts.join(' ').replaceAll(_diacritics, '');
}

String _digits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

final _wordPattern = RegExp('[\u0621-\u065F\u0670\u06D6-\u06ED]+');
final _existingQuran = RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true);

/// Character ranges that already carry markup and must not be matched again.
List<List<int>> _markedRegions(String s) =>
    _existingQuran.allMatches(s).map((m) => [m.start, m.end]).toList();

List<_Token> _tokenise(String s, List<List<int>> skip) {
  final out = <_Token>[];
  for (final m in _wordPattern.allMatches(s)) {
    if (skip.any((r) => m.start < r[1] && m.end > r[0])) continue;
    final n = _norm(m.group(0)!);
    if (n.isEmpty) continue;
    out.add(_Token(n, m.start, m.end));
  }
  return out;
}

class _Token {
  final String norm;
  final int start;
  final int end;
  _Token(this.norm, this.start, this.end);
}

class _Hit {
  final _Surah surah;
  final int index;
  _Hit(this.surah, this.index);
}

class _Span {
  final int start;
  final int end;
  final _Surah surah;
  final int wordStart;
  final int wordEnd;
  _Span(this.start, this.end, this.surah, this.wordStart, this.wordEnd);
  int get length => end - start;
}

/// A surah flattened into one word array, with the ayah boundaries kept.
class _Surah {
  final int number;
  final String name;
  final display = <String>[];
  final norm = <String>[];
  final _starts = <int>[];
  final _numbers = <int>[];

  _Surah(this.number, this.name);

  void add(int ayahNumber, List<String> words) {
    _starts.add(display.length);
    _numbers.add(ayahNumber);
    display.addAll(words);
    norm.addAll(words.map(_norm));
  }

  int startOf(int i) => _starts[i];
  int endOf(int i) => i + 1 < _starts.length ? _starts[i + 1] : display.length;
  int numberOf(int i) => _numbers[i];

  int ayahAt(int word) {
    var lo = 0, hi = _starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_starts[mid] <= word) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
