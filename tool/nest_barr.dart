import 'dart:io';

/// Builds the nested repetition in hizb al-barr: the inner invocation is said
/// three times inside an outer block that is itself said three times, the way
/// the printed book shows it.
void main() {
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  const m = '\u00A7B\u00A7';

  const outerStart = '\u064A\u064E\u0627 \u0623\u0644\u0644\u0651\u0647\u064F \u064A\u064E\u0627 \u0631\u064E\u062D\u0652\u0645\u0646\u064F';
  // The duplicated invocation plus its "repeated each time" note.
  const dupFrom = '\u0648\u062A\u064F\u0643\u064E\u0631\u064E\u0631\u064F';
  const dupTo = '\u0623\u063A\u0650\u0640\u062B\u0640\u0646\u064E\u0627';

  final s = text.indexOf(outerStart);
  if (s < 0) throw 'outer start not found';

  final noteStart = text.indexOf(dupFrom, s);
  if (noteStart < 0) throw 'note not found';
  final dupEnd = text.indexOf(dupTo, noteStart);
  if (dupEnd < 0) throw 'duplicate not found';
  // Swallow the trailing marker and its "{ three times }".
  var after = dupEnd + dupTo.length;
  after = text.indexOf('}', after) + 1;

  // Everything from the note to the duplicate's own instruction goes away.
  text = text.substring(0, noteStart) + text.substring(after);

  // Close the outer block just after the inner instruction.
  final innerEnd = text.indexOf('}', text.indexOf(m, s)) + 1;
  text = text.substring(0, innerEnd) + m + text.substring(innerEnd);
  text = text.substring(0, s) + m + text.substring(s);

  file.writeAsStringSync(text);
  stdout.writeln('nested block built');
}
