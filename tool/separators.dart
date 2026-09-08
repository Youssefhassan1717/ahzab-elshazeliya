import 'dart:io';

/// Puts every separator on the same footing: one design, one space either side.
///
/// A comma that leans against a Qur'anic block is not punctuation, it is a
/// separator the book wrote as a comma - those become \u06DE. A comma inside a
/// sentence stays a comma; it just gets its spacing fixed.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final rows = <String>[];
  var promoted = 0, inserted = 0, respaced = 0, latin = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var c = blocks[b].group(1)!;
    if (ids[b] == 'ad3eya') {
      rows.add('${ids[b].padRight(18)} left as it is');
      continue;
    }

    final kept = <String>[];
    c = c.replaceAllMapped(
        RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), (m) {
      kept.add(m.group(0)!);
      return '\u0001${kept.length - 1}\u0001';
    });

    latin += RegExp(',').allMatches(c).length;
    c = c.replaceAll(',', '\u060C');

    // A comma against a Qur'anic block was standing in for a separator.
    var before = c;
    c = c.replaceAll(RegExp('\\s*\u060C\\s*(?=\u0001)'), ' \u06DE ');
    c = c.replaceAllMapped(
        RegExp('(\u0001\\d+\u0001)\\s*\u060C\\s*'), (m) => '${m[1]} \u06DE ');
    if (c != before) promoted++;

    // Two Qur'anic blocks with nothing between them still need a separator.
    before = c;
    c = c.replaceAllMapped(
        RegExp('(\u0001\\d+\u0001)\\s*(?=\u0001\\d+\u0001)'),
        (m) => '${m[1]} \u06DE ');
    if (c != before) inserted++;

    // A mark cannot open a word: it was typed before its letter, not after.
    c = c.replaceAllMapped(
        RegExp('(\\s)([\u064B-\u0652\u0670]+)([\u0621-\u064A])'),
        (m) => '${m[1]}${m[3]}${m[2]}');
    // One with no letter after it belongs to nothing at all.
    c = c.replaceAllMapped(
        RegExp('(^|[\u06DE\u060C])\\s*[\u064B-\u0652\u0670]+'), (m) => m[1]!);

    // A comma next to a separator is the same pause written twice, and a run
    // of separators is still one pause. Collapse both before spacing them.
    c = c.replaceAll(RegExp('[\u06DE\u060C\\s]*\u06DE[\u06DE\u060C\\s]*'), '\u06DE');
    c = c.replaceAll(RegExp('\\s*\u06DE\\s*'), ' \u06DE ');
    c = c.replaceAll(RegExp('\\s*\u060C\\s*'), '\u060C ');
    c = c.replaceAll(RegExp('\\s*\u061B\\s*'), '\u061B ');
    c = c.replaceAll(RegExp('\\s*:\\s*'), ': ');
    c = c.replaceAllMapped(RegExp(r'\{\s*([^}]*?)\s*\}'), (m) => '{ ${m[1]} }');
    c = c.replaceAllMapped(RegExp(r'\(\s*([^)]*?)\s*\)'), (m) => '( ${m[1]} )');
    c = c.replaceAllMapped(RegExp(r'\[\s*([^\]]*?)\s*\]'), (m) => '[ ${m[1]} ]');
    c = c.replaceAll(RegExp(' {2,}'), ' ');
    c = c.replaceAll(RegExp('^[\\s\u06DE\u060C]+'), '');
    c = c.replaceAll(RegExp('[\\s\u06DE\u060C]+\$'), '');
    c = c.trim();
    respaced++;

    for (var i = 0; i < kept.length; i++) {
      c = c.replaceAll('\u0001$i\u0001', kept[i]);
    }

    final marks = RegExp('\u06DE').allMatches(c).length;
    final commas = RegExp('\u060C').allMatches(c).length;
    final bad = RegExp('[^ ]\u06DE|\u06DE[^ ]').allMatches(c).length +
        RegExp(' \u060C').allMatches(c).length;
    rows.add('${ids[b].padRight(18)} \u06DE $marks'.padRight(28) +
        '\u060C $commas'.padRight(10) +
        (bad == 0 ? 'spacing ok' : 'STILL WRONG: $bad'));

    text = text.substring(0, blocks[b].start) +
        "content: r'''$c'''" +
        text.substring(blocks[b].end);
  }

  if (apply) file.writeAsStringSync(text);
  for (final r in rows.reversed) {
    stdout.writeln(r);
  }
  stdout.writeln('\nlatin commas folded: $latin, commas promoted to separators '
      'in $promoted ahzab, separators inserted in $inserted, respaced $respaced'
      '${apply ? " - applied" : " - dry run"}');
}
