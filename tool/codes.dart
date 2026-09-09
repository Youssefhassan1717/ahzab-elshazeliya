import 'dart:io';

/// Prints the codepoints around a phrase, so an odd-looking glyph can be named.
/// Usage: dart run tool/codes.dart <hizbId> <phrase> [after]
void main(List<String> args) {
  final id = args[0];
  final phrase = args[1];
  final after = args.length > 2 ? int.parse(args[2]) : 12;

  final text = File('lib/data/ahzab_data.dart').readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final b = ids.indexOf(id);
  if (b < 0) {
    stdout.writeln('no hizb "$id"');
    return;
  }
  final c = blocks[b].group(1)!;
  final i = c.indexOf(phrase);
  if (i < 0) {
    stdout.writeln('"$phrase" not found in $id');
    return;
  }
  final from = i + phrase.length;
  final to = (from + after).clamp(0, c.length);
  stdout.writeln('$id @$i  ...${c.substring((i - 12).clamp(0, c.length), to)}...');
  for (final r in c.substring(from, to).runes) {
    final hex = r.toRadixString(16).toUpperCase().padLeft(4, '0');
    final shown = r == 0x20 ? 'SPACE' : String.fromCharCode(r);
    stdout.writeln('  U+$hex  $shown');
  }
}
