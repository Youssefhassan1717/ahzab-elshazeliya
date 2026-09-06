import 'dart:convert';
import 'dart:io';

/// Reports Qur'anic passages that were *nearly* complete, i.e. the hizb quotes
/// a whole ayah but its spelling differs from the mushaf so the match stopped
/// short. These are the ones the marker pass could not pick up.
void main() {
  const gram = 4;
  final raw = jsonDecode(File('tool/quran.json').readAsStringSync()) as List;
  final surahs = <int, _Surah>{};
  for (final e in raw) {
    var words = (e['text'] as String).trim().split(RegExp(r'\s+'));
    if (e['ayah'] == 1 && e['surah'] != 1 && words.length > 4) {
      if (words.take(4).map(_norm).join(' ') == _basmala) words = words.sublist(4);
    }
    surahs.putIfAbsent(e['surah'], () => _Surah(e['surah'])).add(e['ayah'], words);
  }

  final index = <String, List<List<int>>>{};
  for (final s in surahs.values) {
    for (var i = 0; i + gram <= s.norm.length; i++) {
      index.putIfAbsent(s.norm.sublist(i, i + gram).join(' '), () => [])
          .add([s.number, i]);
    }
  }

  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final marked = RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true);

  var near = 0, partial = 0;
  final buf = StringBuffer();
  for (var b = 0; b < blocks.length; b++) {
    final content = blocks[b].group(1)!;
    final skip = marked.allMatches(content).map((m) => [m.start, m.end]).toList();
    final tokens = <List<dynamic>>[];
    for (final m in RegExp('[\u0621-\u065F\u0670\u06D6-\u06ED]+').allMatches(content)) {
      if (skip.any((r) => m.start < r[1] && m.end > r[0])) continue;
      final n = _norm(m.group(0)!);
      if (n.isNotEmpty) tokens.add([n, m.start, m.end]);
    }

    var t = 0;
    while (t + gram <= tokens.length) {
      final hits = index[tokens.sublist(t, t + gram).map((x) => x[0]).join(' ')];
      if (hits == null) {
        t++;
        continue;
      }
      var bestLen = 0, bestRatio = 0.0, bestSurah = 0, bestAyah = 0, bestEnd = t;
      for (final hit in hits) {
        final s = surahs[hit[0]]!;
        var ws = hit[1] as int, ts = t;
        while (ws > 0 && ts > 0 && s.norm[ws - 1] == tokens[ts - 1][0]) {
          ws--;
          ts--;
        }
        var we = hit[1] as int, te = t;
        while (we < s.norm.length && te < tokens.length && s.norm[we] == tokens[te][0]) {
          we++;
          te++;
        }
        final a = s.ayahAt(ws);
        final span = s.endOf(a) - s.startOf(a);
        final ratio = (we - ws) / span;
        if (te - ts > bestLen) {
          bestLen = te - ts;
          bestRatio = ratio;
          bestSurah = s.number;
          bestAyah = s.numberOf(a);
          bestEnd = te;
        }
      }
      if (bestLen < 6) {
        t++;
        continue;
      }
      if (bestRatio >= 0.8) {
        near++;
        buf.writeln('[${ids[b]}] $bestSurah:$bestAyah  '
            '${(bestRatio * 100).round()}% of the ayah, $bestLen words');
      } else {
        partial++;
      }
      t = bestEnd;
    }
  }
  File('_coverage.txt').writeAsStringSync(buf.toString());
  stdout.writeln('near-complete but unmarked: $near');
  stdout.writeln('clearly partial quotes    : $partial');
}

final _diacritics = RegExp('[\u064B-\u0652\u0670\u0640\u06D6-\u06ED]');
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

class _Surah {
  final int number;
  final norm = <String>[];
  final _starts = <int>[];
  final _numbers = <int>[];
  _Surah(this.number);

  void add(int n, List<String> words) {
    _starts.add(norm.length);
    _numbers.add(n);
    norm.addAll(words.map(_norm));
  }

  int startOf(int i) => _starts[i];
  int endOf(int i) => i + 1 < _starts.length ? _starts[i + 1] : norm.length;
  int numberOf(int i) => _numbers[i];

  int ayahAt(int w) {
    var lo = 0, hi = _starts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_starts[mid] <= w) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
