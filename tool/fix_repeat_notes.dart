import 'dart:io';

/// Moves a leading "and it is repeated each time…" note out of a frame — it is
/// an instruction to the reader, not part of the passage being repeated.
void main() {
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  const marker = '\u00A7B\u00A7';

  final diacritics = RegExp('[\u064B-\u0652\u0670\u0640]');
  String norm(String s) => s.replaceAll(diacritics, '').replaceAll('\u0629', '\u0647');

  const heads = {'\u0648\u062A\u0643\u0631\u0631', '\u0648\u064A\u0643\u0631\u0631'};
  const fillers = {
    '\u0641\u0649', '\u0641\u064A', '\u0643\u0644',
    '\u0645\u0631\u0647', '\u062C\u0645\u0644\u0647',
  };

  var moved = 0;
  var cursor = 0;
  while (true) {
    final open = text.indexOf(marker, cursor);
    if (open < 0) break;
    final close = text.indexOf(marker, open + marker.length);
    if (close < 0) break;
    cursor = close + marker.length;

    final inner = text.substring(open + marker.length, close);
    final tokens = inner.split(RegExp(r' +'));
    var head = -1;
    for (var i = 0; i < tokens.length; i++) {
      if (heads.contains(norm(tokens[i]))) head = i;
    }
    if (head < 0) continue;

    var cut = head;
    while (cut + 1 < tokens.length && fillers.contains(norm(tokens[cut + 1]))) {
      cut++;
    }
    if (cut + 1 >= tokens.length) continue;

    final note = tokens.sublist(0, cut + 1).join(' ');
    final rest = tokens.sublist(cut + 1).join(' ');
    text = text.substring(0, open) + note + ' ' + marker + rest + text.substring(close);
    moved++;
    cursor = open;
  }

  file.writeAsStringSync(text);
  stdout.writeln('notes moved out of frames: $moved');
}
