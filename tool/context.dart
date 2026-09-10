import 'dart:io';

/// Prints a window of text around each phrase given on the command line.
/// Usage: dart run tool/context.dart <file> <phrase> [phrase...]
void main(List<String> args) {
  final text = File(args[0]).readAsStringSync();
  for (final needle in args.skip(1)) {
    var from = 0;
    var found = false;
    while (true) {
      final i = text.indexOf(needle, from);
      if (i < 0) break;
      found = true;
      final s = (i - 340).clamp(0, text.length);
      final e = (i + 220).clamp(0, text.length);
      stdout.writeln('=== $needle ===');
      stdout.writeln(text.substring(s, e).replaceAll('\n', ' / '));
      stdout.writeln();
      from = i + needle.length;
    }
    if (!found) stdout.writeln('$needle: not found\n');
  }
}
