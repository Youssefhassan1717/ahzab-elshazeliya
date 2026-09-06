import 'dart:convert';
import 'dart:io';

/// Explains why a phrase in a hizb is or is not recognised as Qur'an.
/// Usage: dart run tool/why.dart <hizbId> <wordOffset>
void main(List<String> args) {
  final id = args.isNotEmpty ? args[0] : 'barr';
  final at = args.length > 1 ? int.parse(args[1]) : 0;
  const gram = 4;

  final raw = jsonDecode(File('tool/quran.json').readAsStringSync()) as List;
  final surahs = <int, List<String>>{};
  final names = <int, String>{};
  for (final e in raw) {
    var words = (e['text'] as String).trim().split(RegExp(r'\s+'));
    surahs.putIfAbsent(e['surah'], () => []).addAll(words.map(_norm));
    names[e['surah']] = e['name'];
  }

  final index = <String, List<String>>{};
  for (final entry in surahs.entries) {
    final w = entry.value;
    for (var i = 0; i + gram <= w.length; i++) {
      index
          .putIfAbsent(w.sublist(i, i + gram).map(_loose).join(' '), () => [])
          .add('${names[entry.key]}@$i');
    }
  }

  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final b = ids.indexOf(id);
  stdout.writeln('ids found: ${ids.length}, blocks found: ${blocks.length}');
  if (b < 0 || b >= blocks.length) {
    stdout.writeln('no block for "$id"');
    return;
  }

  final content = blocks[b].group(1)!;
  final masked = RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true)
      .allMatches(content)
      .map((m) => [m.start, m.end])
      .toList();
  final tokens = <String>[];
  for (final m in RegExp('[\u0621-\u065F\u0670\u06D6-\u06ED]+').allMatches(content)) {
    if (masked.any((r) => m.start < r[1] && m.end > r[0])) continue;
    final n = _norm(m.group(0)!);
    if (n.isNotEmpty) tokens.add(n);
  }

  stdout.writeln('tokens: ${tokens.length}');
  for (var i = at; i < at + 12 && i + gram <= tokens.length; i++) {
    final key = tokens.sublist(i, i + gram).map(_loose).join(' ');
    final hits = index[key];
    stdout.writeln('$i  ${tokens[i]}  ->  $key  ::  '
        '${hits == null ? "NO HIT" : "${hits.length} hits: ${hits.take(3).join(", ")}"}');
  }

  // Replay the expansion from the seed at [at] so the stopping word is visible.
  final key = tokens.sublist(at, at + gram).map(_loose).join(' ');
  final hits = index[key];
  if (hits == null) return;
  final parts = hits.first.split('@');
  final sNum = names.entries.firstWhere((e) => e.value == parts[0]).key;
  final words = surahs[sNum]!;
  var ws = int.parse(parts[1]), te = at, we = int.parse(parts[1]);
  while (we < words.length && te < tokens.length && _sameWord(tokens[te], words[we])) {
    we++;
    te++;
  }
  stdout.writeln('\nexpansion from $ws: reached $we (${we - ws} words)');
  if (we < words.length && te < tokens.length) {
    stdout.writeln('stopped at hizb "${tokens[te]}" vs mushaf "${words[we]}"');
  }
}

bool _sameWord(String a, String b) {
  if (a == b) return true;
  final shortest = a.length < b.length ? a.length : b.length;
  if (shortest < 3) return false;
  final budget = shortest <= 4 ? 1 : 2;
  if ((a.length - b.length).abs() > budget) return false;
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
  return prev[b.length] <= budget;
}

final _diacritics = RegExp('[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]');

String _norm(String s) => s
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[\u0623\u0625\u0622\u0671]'), '\u0627')
    .replaceAll('\u0649', '\u064A')
    .replaceAll('\u0629', '\u0647')
    .replaceAll('\u0624', '\u0648')
    .replaceAll('\u0626', '\u064A')
    .replaceAll('\u0621', '');

String _loose(String n) {
  if (n.length <= 3) return n;
  final s = n.replaceAll(RegExp('[\u0627\u0648\u064A]'), '');
  return s.length < 3 ? n : s;
}
