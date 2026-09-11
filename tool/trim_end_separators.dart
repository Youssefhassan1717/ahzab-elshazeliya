import 'dart:io';

/// Reports (and with --apply, removes) separators left dangling at the end of
/// a hizb, a dua, or a section — an ending should be a full stop, not a ۞.
///
///   dart run tool/trim_end_separators.dart [--apply]
void main(List<String> args) {
  final apply = args.contains('--apply');
  const files = ['lib/data/ahzab_data.dart', 'lib/data/muqaddima.dart'];

  if (args.contains('--tails')) {
    _printTails(files);
    return;
  }

  // A separator (and any spaces around it) sitting immediately before the end
  // of the content, a blank line, or a section marker.
  final patterns = <String, RegExp>{
    'end of content': RegExp(r"[ \t]*\u06DE[ \t]*(?=''')"),
    'end of paragraph': RegExp(r"[ \t]*\u06DE[ \t]*(?=\r?\n)"),
    'before a section': RegExp(r"[ \t]*\u06DE[ \t]*(?=\u00A7SECTION\u00A7)"),
  };

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      stdout.writeln('$path: missing');
      continue;
    }

    var text = file.readAsStringSync();
    var total = 0;

    for (final entry in patterns.entries) {
      final hits = entry.value.allMatches(text).length;
      if (hits == 0) continue;
      total += hits;
      stdout.writeln('$path — ${entry.key}: $hits');
      if (apply) text = text.replaceAll(entry.value, '');
    }

    stdout.writeln('$path — total: $total');
    if (apply && total > 0) file.writeAsStringSync(text);
  }

  stdout.writeln(apply ? 'applied' : 'dry run — pass --apply to write');
}

/// Writes the last characters of every hizb, dua and section to _tails.txt,
/// because the console mangles Arabic.
void _printTails(List<String> files) {
  final out = StringBuffer();
  for (final path in files) {
    final text = File(path).readAsStringSync();
    for (final block in RegExp(r"content: r'''([\s\S]*?)'''").allMatches(text)) {
      final body = block.group(1)!;
      final pieces = body.split(RegExp(r'\r?\n\s*\r?\n|\u00A7SECTION\u00A7'));
      for (final piece in pieces) {
        final t = piece.trim();
        if (t.isEmpty) continue;
        final tail = t.length <= 44 ? t : t.substring(t.length - 44);
        out.writeln('...$tail');
      }
    }
  }
  File('_tails.txt').writeAsStringSync(out.toString());
  stdout.writeln('wrote _tails.txt');
}
