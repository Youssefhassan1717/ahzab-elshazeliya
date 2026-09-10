import 'dart:io';

/// Shows where a given character still appears in the hizb texts, hizb by hizb.
/// Qur'anic blocks are excluded, since their references legitimately contain
/// digits and dashes.
/// Usage: dart run tool/where.dart <file> <chars>
void main(List<String> args) {
  final text = File(args[0]).readAsStringSync();
  final wanted = args[1];
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  var total = 0;
  for (var b = 0; b < blocks.length; b++) {
    final c = blocks[b]
        .group(1)!
        .replaceAll(RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), ' ');
    for (final m in RegExp('[${RegExp.escape(wanted)}]').allMatches(c)) {
      total++;
      final s = (m.start - 60).clamp(0, c.length);
      final e = (m.end + 60).clamp(0, c.length);
      stdout.writeln('[${ids[b]}] ...${c.substring(s, e).replaceAll('\n', ' / ')}...');
    }
  }
  stdout.writeln('\ntotal: $total');
}
