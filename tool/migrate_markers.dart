import 'dart:io';

/// Splits the single framing marker into an explicit open/close pair so that
/// nested repetitions can be expressed, and finishes the nested block in barr.
void main() {
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  const old = '\u00A7B\u00A7';
  const open = '\u00A7B\u00A7';
  const close = '\u00A7b\u00A7';

  // Every frame is a simple pair at this point, so alternating is correct.
  final buf = StringBuffer();
  var i = 0, n = 0;
  while (true) {
    final j = text.indexOf(old, i);
    if (j < 0) {
      buf.write(text.substring(i));
      break;
    }
    buf.write(text.substring(i, j));
    buf.write(n.isEven ? open : close);
    n++;
    i = j + old.length;
  }
  text = buf.toString();
  stdout.writeln('markers migrated: $n');

  // In barr the order is outer-open, inner-open, inner-close, outer-close;
  // alternating mislabels the middle two, so set all four explicitly.
  const anchor = '\u064A\u064E\u0627 \u0631\u064E\u0628\u064E\u0651\u0627\u0647\u064F';
  final a = text.indexOf(anchor);
  if (a < 0) throw 'nested anchor not found';

  final marker = RegExp('\u00A7[Bb]\u00A7');
  final positions = marker.allMatches(text).map((m) => m.start).toList();
  final innerOpenAt = positions.lastWhere((p) => p < a);
  final rest = positions.where((p) => p > a).toList();
  final innerCloseAt = rest[0];
  final outerCloseAt = rest[1];
  final outerOpenAt = positions.lastWhere((p) => p < innerOpenAt);

  for (final entry in {
    outerOpenAt: open,
    innerOpenAt: open,
    innerCloseAt: close,
    outerCloseAt: close,
  }.entries) {
    text = text.replaceRange(entry.key, entry.key + 3, entry.value);
  }

  // The outer block carries its own "three times".
  final insertAt = outerCloseAt + close.length;
  text = text.substring(0, insertAt) +
      ' { \u062B\u0644\u0627\u062B\u0627\u064B }' +
      text.substring(insertAt);

  text = text.replaceAll(RegExp(r'  +(?=[\u0600-\u06FF])'), ' ');
  file.writeAsStringSync(text);
  stdout.writeln('nested block finished');
}
