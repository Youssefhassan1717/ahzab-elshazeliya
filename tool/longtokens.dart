import 'dart:io';

/// Lists the longest whitespace-delimited tokens in each hizb, which is how a
/// pair of words accidentally joined together shows up.
void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'lib/data/ahzab_data.dart';
  final min = args.length > 1 ? int.parse(args[1]) : 22;
  final text = File(path).readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  for (var b = 0; b < blocks.length; b++) {
    var c = blocks[b].group(1)!;
    c = c.replaceAll(RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), ' ');
    c = c.replaceAll(RegExp('\u00A7[A-Za-z]+\u00A7'), ' ');
    for (final t in c.split(RegExp(r'\s+'))) {
      final letters = t.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
      if (letters.length >= min) {
        stdout.writeln('[${ids[b]}] ${letters.length}  $t');
      }
    }
  }
}
