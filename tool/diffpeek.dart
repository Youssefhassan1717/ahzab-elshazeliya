import 'dart:io';

/// Prints the same passage from the committed file and the working copy.
/// Usage: dart run tool/diffpeek.dart <text> [chars]
void main(List<String> args) {
  final needle = args[0];
  final span = args.length > 1 ? int.parse(args[1]) : 110;
  for (final f in ['_head.dart', 'lib/data/ahzab_data.dart']) {
    final file = File(f);
    if (!file.existsSync()) {
      stdout.writeln('$f: missing');
      continue;
    }
    final t = file.readAsStringSync();
    var from = 0;
    var shown = 0;
    while (shown < 3) {
      final i = t.indexOf(needle, from);
      if (i < 0) break;
      final s = (i - 30).clamp(0, t.length);
      final e = (i + span).clamp(0, t.length);
      stdout.writeln('$f @$i  ${t.substring(s, e)}');
      from = i + 1;
      shown++;
    }
    if (shown == 0) stdout.writeln('$f: not found');
  }
}
