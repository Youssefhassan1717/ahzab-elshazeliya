import 'dart:io';

/// Prints where a phrase sits in the dumped hizb, with surrounding context.
void main(List<String> args) {
  final text = File('_dump.txt').readAsStringSync();
  for (final needle in args) {
    var from = 0;
    while (true) {
      final i = text.indexOf(needle, from);
      if (i < 0) break;
      final s = (i - 80).clamp(0, text.length);
      final e = (i + needle.length + 80).clamp(0, text.length);
      stdout.writeln('@$i  ...${text.substring(s, e).replaceAll("\n", " | ")}...');
      from = i + 1;
    }
    stdout.writeln('---');
  }
}
