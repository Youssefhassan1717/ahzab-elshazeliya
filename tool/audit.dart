import 'dart:io';

/// Reports the typographic snags in the hizb texts: the book's own brackets,
/// blank lines, split words and repeat labels.
void main() {
  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final out = StringBuffer();

  out.writeln('=== 1. LITERAL BRACKETS IN THE SOURCE ===');
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    for (final m in RegExp(r'[()\[\]\uFD3F\uFD3E]').allMatches(c)) {
      final from = (m.start - 45).clamp(0, c.length);
      final to = (m.end + 45).clamp(0, c.length);
      out.writeln('[${ids[b]}] ${m.group(0)}  ...'
          '${c.substring(from, to).replaceAll('\n', ' / ')}...');
    }
  }

  out.writeln('\n=== 2. BLANK LINES ===');
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    final blanks = RegExp(r'\n[ \t]*\n').allMatches(c).toList();
    final singles = RegExp(r'\n').allMatches(c).length;
    if (blanks.isEmpty) continue;
    out.writeln('[${ids[b]}] blank runs: ${blanks.length}, newlines total: $singles');
    for (final m in blanks) {
      final from = (m.start - 50).clamp(0, c.length);
      final to = (m.end + 50).clamp(0, c.length);
      out.writeln('    ...${c.substring(from, to).replaceAll('\n', ' \\n ')}...');
    }
  }

  out.writeln('\n=== 3. SPLIT WORDS (a lone letter or two between spaces) ===');
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    for (final m in RegExp(' ([\u0621-\u064A][\u064B-\u0652]?) ').allMatches(c)) {
      final from = (m.start - 40).clamp(0, c.length);
      final to = (m.end + 25).clamp(0, c.length);
      out.writeln('[${ids[b]}] "${m.group(1)}"  ...'
          '${c.substring(from, to).replaceAll('\n', ' / ')}...');
    }
  }

  out.writeln('\n=== 4. REPEAT LABELS ===');
  final labels = <String, int>{};
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    for (final m in RegExp(r'\{([^}]*)\}').allMatches(c)) {
      final l = m.group(1)!.trim();
      labels[l] = (labels[l] ?? 0) + 1;
    }
    final open = '{'.allMatches(c).length, close = '}'.allMatches(c).length;
    if (open != close) out.writeln('[${ids[b]}] UNBALANCED  { $open  } $close');
  }
  labels.forEach((k, v) => out.writeln('  $v x  "$k"'));

  out.writeln('\n=== 5. SEPARATORS ===');
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    out.writeln('[${ids[b]}] asterisks: ${'*'.allMatches(c).length}');
  }

  File('_audit.txt').writeAsStringSync(out.toString());
  stdout.writeln('wrote _audit.txt (${out.length} chars)');
}

extension on String {
  Iterable<Match> allMatches(String input) => RegExp(RegExp.escape(this)).allMatches(input);
}
