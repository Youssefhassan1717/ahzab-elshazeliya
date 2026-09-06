import 'dart:convert';
import 'dart:io';

/// Marks Qur'anic passages in the ahzab as `§Q§reference|mushaf text§Q§`.
///
/// A hizb often quotes a whole ayah but spells a word or two differently from
/// the mushaf, so an exact match stops short. When a match already covers most
/// of an ayah, the edges are extended over hizb words that are clearly the same
/// word, and the passage is written out in full from the mushaf.
void main(List<String> args) {
  final apply = args.contains('--apply');
  const gram = 4;
  const minWords = 6;
  const minCoverage = 0.7;

  final raw = jsonDecode(File('tool/quran.json').readAsStringSync()) as List;
  final surahs = <int, _Surah>{};
  for (final e in raw) {
    var words = (e['text'] as String).trim().split(RegExp(r'\s+'));
    if (e['ayah'] == 1 && e['surah'] != 1 && words.length > 4) {
      if (words.take(4).map(_norm).join(' ') == _basmala) words = words.sublist(4);
    }
    // A waqf mark can stand alone between two words; left in, it looks like a
    // word that matches nothing and every passage stops dead at it.
    words = words
        .map((w) => w.replaceAll(_marks, ''))
        .where((w) => _norm(w).isNotEmpty)
        .toList();
    surahs
        .putIfAbsent(e['surah'], () => _Surah(e['surah'], _surahName(e['name'])))
        .add(e['ayah'], words);
  }

  // The seed is indexed on the consonantal skeleton: the mushaf's rasm and the
  // hizb's modern spelling differ often enough (السموت / السماوات) that an
  // exact seed simply never fires on those ayat.
  final index = <String, List<_Hit>>{};
  for (final s in surahs.values) {
    for (var i = 0; i + gram <= s.loose.length; i++) {
      index
          .putIfAbsent(s.loose.sublist(i, i + gram).join(' '), () => [])
          .add(_Hit(s, i));
    }
  }

  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final existing = RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true);

  final report = StringBuffer();
  var exact = 0, stretched = 0, skipped = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var content = blocks[b].group(1)!;
    final masked = existing.allMatches(content).map((m) => [m.start, m.end]).toList();
    final tokens = <_Token>[];
    for (final m in _wordPattern.allMatches(content)) {
      if (masked.any((r) => m.start < r[1] && m.end > r[0])) continue;
      final n = _norm(m.group(0)!);
      if (n.isNotEmpty) tokens.add(_Token(n, m.start, m.end));
    }

    final spans = <_Span>[];
    var t = 0;
    while (t + gram <= tokens.length) {
      final hits = index[tokens.sublist(t, t + gram).map((x) => x.loose).join(' ')];
      if (hits == null) {
        t++;
        continue;
      }
      _Span? best;
      for (final hit in hits) {
        var ws = hit.index, ts = t;
        while (ws > 0 &&
            ts > 0 &&
            _sameWord(tokens[ts - 1].norm, hit.surah.norm[ws - 1])) {
          ws--;
          ts--;
        }
        var we = hit.index, te = t;
        while (we < hit.surah.norm.length &&
            te < tokens.length &&
            _sameWord(tokens[te].norm, hit.surah.norm[we])) {
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
      // A span may reach only backwards from the seed, so the cursor has to be
      // nudged along by hand or the same seed is found for ever.
      t = best.end > t ? best.end : t + 1;
    }

    final ready = <_Ready>[];
    for (final span in spans) {
      final s = span.surah;
      var ws = span.wordStart, we = span.wordEnd;
      // The span is word-for-word, so one offset maps mushaf to hizb throughout.
      final off = span.start - ws;

      var firstAyah = s.ayahAt(ws);
      var lastAyah = s.ayahAt(we - 1);
      final coverage = (we - ws) / (s.endOf(lastAyah) - s.startOf(firstAyah));

      // Reach back to the head of the first ayah; when the hizb does not have
      // it, that ayah is only half quoted, so drop it and keep the rest.
      final from = s.startOf(firstAyah);
      while (ws > from &&
          ws + off > 0 &&
          _sameWord(tokens[ws + off - 1].norm, s.norm[ws - 1])) {
        ws--;
      }
      if (ws != from && firstAyah < lastAyah) {
        firstAyah++;
        ws = s.startOf(firstAyah);
      }

      final to = s.endOf(lastAyah);
      while (we < to &&
          we + off < tokens.length &&
          _sameWord(tokens[we + off].norm, s.norm[we])) {
        we++;
      }
      if (we != to && lastAyah > firstAyah) {
        lastAyah--;
        we = s.endOf(lastAyah);
      }

      final start = ws + off, end = we + off;
      if (ws != s.startOf(firstAyah) ||
          we != s.endOf(lastAyah) ||
          we - ws < 4 ||
          start < 0 ||
          end > tokens.length) {
        if (coverage >= minCoverage) {
          report.writeln('[${ids[b]}] MISSED ${s.name} '
              '${_digits(s.numberOf(s.ayahAt(span.wordStart)))} '
              '${(coverage * 100).round()}% - not a whole ayah');
        }
        skipped++;
        continue;
      }
      we - ws == span.wordEnd - span.wordStart ? exact++ : stretched++;
      // The basmala opens most ahzab as a formula, not as a quotation.
      if (s.number == 1 && firstAyah == 0 && lastAyah == 0) continue;

      // Rewriting the passage would wipe out any marker caught inside it, so
      // give back the trailing ayat until what is left is clear of them.
      var last = lastAyah, end2 = end;
      while (last >= firstAyah &&
          content
              .substring(tokens[start].start, tokens[end2 - 1].end)
              .contains('\u00A7')) {
        last--;
        if (last >= firstAyah) end2 = s.endOf(last) + off;
      }
      if (last < firstAyah || end2 - start < 4) {
        report.writeln('[${ids[b]}] SKIPPED ${s.name} '
            '${_digits(s.numberOf(firstAyah))} - a marker sits inside it');
        continue;
      }
      ready.add(_Ready(start, end2, s, firstAyah, last));
    }

    // Two passages that run into each other, or that share an ayah, are really
    // one quotation - printing them apart would repeat an ayah.
    for (var k = ready.length - 1; k > 0; k--) {
      final prev = ready[k - 1], cur = ready[k];
      if (prev.surah.number != cur.surah.number) continue;
      if (cur.firstAyah <= prev.lastAyah + 1) {
        // Extending the edges can make neighbours run into one another.
        final touching = cur.start <= prev.end;
        if (!touching) {
          final between =
              content.substring(tokens[prev.end - 1].end, tokens[cur.start].start);
          if (RegExp('[\u0621-\u064A\u00A7]').hasMatch(between)) continue;
        }
      } else if (!_bridges(prev, cur, tokens) ||
          content
              .substring(tokens[prev.end - 1].end, tokens[cur.start].start)
              .contains('\u00A7')) {
        continue;
      }
      ready[k - 1] = _Ready(
          prev.start,
          cur.end > prev.end ? cur.end : prev.end,
          prev.surah,
          prev.firstAyah,
          cur.lastAyah > prev.lastAyah ? cur.lastAyah : prev.lastAyah);
      ready.removeAt(k);
    }

    for (final r in ready.reversed) {
      final s = r.surah;
      final buf = StringBuffer();
      for (var a = r.firstAyah; a <= r.lastAyah; a++) {
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(s.display.sublist(s.startOf(a), s.endOf(a)).join(' '));
        buf.write(' ${_digits(s.numberOf(a))}');
      }

      final ref = r.firstAyah == r.lastAyah
          ? '${s.name}: ${_digits(s.numberOf(r.firstAyah))}'
          : '${s.name}: ${_digits(s.numberOf(r.firstAyah))} - '
              '${_digits(s.numberOf(r.lastAyah))}';

      content = content.substring(0, tokens[r.start].start) +
          '\u00A7Q\u00A7$ref|$buf\u00A7Q\u00A7' +
          content.substring(tokens[r.end - 1].end);
      report.writeln('[${ids[b]}] $ref');
    }

    text = text.substring(0, blocks[b].start) +
        "content: r'''$content'''" +
        text.substring(blocks[b].end);
  }

  File('_quran_report.txt').writeAsStringSync(report.toString());
  if (apply) file.writeAsStringSync(text);
  stdout.writeln('marked: ${exact + stretched} (exact $exact, extended $stretched), '
      'left as partial: $skipped${apply ? " - applied" : " - dry run"}');
}

/// The consonantal skeleton, which the mushaf's rasm and the hizb's spelling
/// still agree on when the long vowels they write differ. Short words keep
/// their vowels - stripping those leaves too little to tell them apart.
String _loose(String n) {
  if (n.length <= 3) return n;
  final s = n.replaceAll(RegExp('[\u0627\u0648\u064A]'), '');
  return s.length < 3 ? n : s;
}

/// A short ayah between two matched passages is never found on its own, so the
/// gap is closed when the hizb words in between are the missing mushaf words.
bool _bridges(_Ready prev, _Ready cur, List<_Token> tokens) {
  if (cur.start < prev.end) return false;
  final s = prev.surah;
  final from = s.endOf(prev.lastAyah), to = s.startOf(cur.firstAyah);
  if (to - from != cur.start - prev.end) return false;
  if (to - from > 15) return false;
  for (var i = 0; i < to - from; i++) {
    if (!_sameWord(tokens[prev.end + i].norm, s.norm[from + i])) return false;
  }
  return true;
}

/// Two spellings of the same word: identical, or within a couple of letters of
/// each other, which is all that separates the hizb's spelling from the mushaf.
final _sameWordMemo = <String, bool>{};

bool _sameWord(String a, String b) =>
    _sameWordMemo.putIfAbsent('$a|$b', () => _compare(a, b));

bool _compare(String a, String b) {
  if (a == b) return true;
  final shortest = a.length < b.length ? a.length : b.length;
  if (shortest < 3) return false;
  final budget = shortest <= 4 ? 1 : 2;
  if ((a.length - b.length).abs() > budget) return false;
  return _distance(a, b, budget) <= budget;
}

int _distance(String a, String b, int cap) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  final row = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    row[0] = i;
    var best = row[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = prev[j - 1] + cost;
      if (prev[j] + 1 < v) v = prev[j] + 1;
      if (row[j - 1] + 1 < v) v = row[j - 1] + 1;
      row[j] = v;
      if (v < best) best = v;
    }
    if (best > cap) return cap + 1;
    prev = List<int>.from(row);
  }
  return prev[b.length];
}

final _diacritics = RegExp('[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]');
final _marks = RegExp('[\u06D6-\u06ED]');
final _wordPattern = RegExp('[\u0621-\u065F\u0670\u06D6-\u06ED]+');
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
  // Vowels go, but the maddah stays - without it آل عمران and صٓ lose a letter.
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

class _Token {
  final String norm;
  final String loose;
  final int start;
  final int end;
  _Token(this.norm, this.start, this.end) : loose = _loose(norm);
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

class _Ready {
  final int start;
  final int end;
  final _Surah surah;
  final int firstAyah;
  final int lastAyah;
  _Ready(this.start, this.end, this.surah, this.firstAyah, this.lastAyah);
}

class _Surah {
  final int number;
  final String name;
  final display = <String>[];
  final norm = <String>[];
  final loose = <String>[];
  final _starts = <int>[];
  final _numbers = <int>[];

  _Surah(this.number, this.name);

  void add(int ayahNumber, List<String> words) {
    _starts.add(display.length);
    _numbers.add(ayahNumber);
    display.addAll(words);
    norm.addAll(words.map(_norm));
    loose.addAll(words.map((w) => _loose(_norm(w))));
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
