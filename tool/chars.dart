import 'dart:io';

/// Lists every non-Arabic, non-marker character in each hizb, so the odd
/// separators and stray punctuation can be seen at a glance.
void main() {
  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final out = StringBuffer();
  final overall = <String, int>{};

  for (var b = 0; b < blocks.length; b++) {
    var c = blocks[b].group(1)!;
    c = c.replaceAll(RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), '');
    c = c.replaceAll(RegExp('\u00A7[A-Za-z]\u00A7'), '');
    c = c.replaceAll(RegExp('\u00A7SECTION\u00A7.*?\u00A7SECTION\u00A7'), '');

    final counts = <String, int>{};
    for (final r in c.runes) {
      final ch = String.fromCharCode(r);
      final arabic = (r >= 0x0621 && r <= 0x065F) ||
          r == 0x0670 ||
          r == 0x0640 ||
          (r >= 0x0671 && r <= 0x06D5);
      if (arabic || ch == ' ') continue;
      counts[ch] = (counts[ch] ?? 0) + 1;
      overall[ch] = (overall[ch] ?? 0) + 1;
    }
    if (counts.isEmpty) continue;
    final list = counts.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    out.writeln('[${ids[b]}]  ${list.map((e) => '${_show(e.key)}x${e.value}').join('  ')}');
  }

  out.writeln('\n=== TOTALS ===');
  final all = overall.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
  for (final e in all) {
    out.writeln('  ${_show(e.key)}  ${e.value}');
  }

  out.writeln('\n=== SEPARATOR RUNS AND SPACING ===');
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    final runs = RegExp('\u06DE(\\s*\u06DE)+').allMatches(c).length;
    final tight = RegExp('[\u0621-\u064A]\u06DE|\u06DE[\u0621-\u064A]').allMatches(c).length;
    final quotes = RegExp('["\u201C\u201D]').allMatches(c).length;
    final dots = RegExp(r'\.').allMatches(c).length;
    if (runs + tight + quotes + dots == 0) continue;
    out.writeln('[${ids[b]}]  doubled runs: $runs, no space: $tight, '
        'quotes: $quotes, dots: $dots');
  }

  File('_chars.txt').writeAsStringSync(out.toString());
  stdout.writeln('wrote _chars.txt');
}

String _show(String ch) {
  final code = ch.runes.first;
  if (ch == '\n') return r'\n';
  if (ch == '\t') return r'\t';
  if (code < 0x20 || code == 0xFEFF) {
    return 'U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }
  return "'$ch'(U+${code.toRadixString(16).toUpperCase().padLeft(4, '0')})";
}
