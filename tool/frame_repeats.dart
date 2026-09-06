import 'dart:io';

/// Wraps every repeated passage in the ornate framing markers.
void main() {
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();

  const marker = '\u00A7B\u00A7';
  const ornament = '\u06DE';
  final blockPattern = RegExp(r"content: r'''(.*?)'''", dotAll: true);
  final bracePattern = RegExp(r'\{[^{}]*\}');

  final blocks = blockPattern.allMatches(text).toList();
  var framed = 0;
  final log = <String>[];

  for (final block in blocks.reversed) {
    var content = block.group(1)!;
    final braces = bracePattern.allMatches(content).toList();

    for (final brace in braces.reversed) {
      var start = 0;
      for (var p = brace.start - 1; p >= 0; p--) {
        final ch = content[p];
        if (ch == '*' || ch == ornament || ch == '}' || ch == '\n' || ch == '\u00A7') {
          start = p + 1;
          break;
        }
      }
      final phrase = content.substring(start, brace.start);
      if (phrase.contains('\u00A7')) continue;
      final trimmed = phrase.trim();
      if (trimmed.length < 2) continue;

      final leadLen = phrase.indexOf(trimmed[0]);
      final lead = phrase.substring(0, leadLen);
      final tail = phrase.substring(leadLen + trimmed.length);
      var inner = trimmed;
      if (inner.startsWith('(') && inner.endsWith(')')) {
        inner = inner.substring(1, inner.length - 1).trim();
      }

      content = content.substring(0, start) +
          lead +
          marker +
          inner +
          marker +
          tail +
          content.substring(brace.start);
      framed++;
      log.add(inner.length > 55 ? '${inner.substring(0, 55)}…' : inner);
    }

    text = text.substring(0, block.start) +
        "content: r'''$content'''" +
        text.substring(block.end);
  }

  file.writeAsStringSync(text);
  final check = marker.allMatches(file.readAsStringSync()).length;
  stdout.writeln('framed: $framed, markers on disk: $check');
  File('_framed.txt').writeAsStringSync(log.reversed.join('\n'));
}

extension on String {
  Iterable<Match> allMatches(String input) => RegExp(RegExp.escape(this)).allMatches(input);
}
