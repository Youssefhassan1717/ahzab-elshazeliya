import 'dart:io';

/// Prints a hizb in numbered chunks so long lines stay readable.
void main(List<String> args) {
  final text = File('_dump.txt').readAsStringSync();
  final from = args.isEmpty ? 0 : int.parse(args[0]);
  final to = args.length < 2 ? text.length : int.parse(args[1]);
  final buf = StringBuffer();
  for (var i = from; i < to && i < text.length; i += 220) {
    final end = (i + 220).clamp(0, text.length);
    buf.writeln('[$i] ${text.substring(i, end).replaceAll("\n", " | ")}');
  }
  File('_slice.txt').writeAsStringSync(buf.toString());
  stdout.writeln('sliced ${from}..$to');
}
