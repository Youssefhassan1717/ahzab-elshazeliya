import 'dart:io';

/// Lists the repeat counts that have no `§B§ … §b§` around the passage they
/// belong to - those are the ones the app cannot colour.
void main() {
  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  var loose = 0, framed = 0;
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b].group(1)!;
    for (final m in RegExp(r'\{([^}]*)\}').allMatches(c)) {
      final before = c.substring(0, m.start).trimRight();
      if (before.endsWith('\u00A7b\u00A7')) {
        framed++;
        continue;
      }
      loose++;
      final from = (m.start - 90).clamp(0, c.length);
      stdout.writeln('[${ids[b]}] ...${c.substring(from, m.end)}');
    }
  }
  stdout.writeln('\nframed: $framed, not framed: $loose');
}
