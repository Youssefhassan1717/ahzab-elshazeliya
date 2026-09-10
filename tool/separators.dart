import 'dart:io';

/// Puts every separator on the same footing: one design, one space either side.
///
/// The mushaf face draws a comma as a small ring, which beside the rosette
/// reads as a second, broken separator, so commas become \u06DE. Pass --dots to
/// fold full stops in as well, for prose that is set like the ahzab.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final dots = args.contains('--dots');
  final target = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');
  final file = File(target.isEmpty ? 'lib/data/ahzab_data.dart' : target);
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  final rows = <String>[];
  var promoted = 0, inserted = 0, respaced = 0, latin = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var c = blocks[b].group(1)!;

    final kept = <String>[];
    c = c.replaceAllMapped(
        RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), (m) {
      kept.add(m.group(0)!);
      return '\u0001${kept.length - 1}\u0001';
    });

    latin += RegExp(',').allMatches(c).length;
    c = c.replaceAll(',', '\u060C');

    // The mushaf face draws a comma as a small ring, so beside the rosette it
    // reads as a second, broken separator. There is only one separator.
    promoted += RegExp('[\u060C\u061B]').allMatches(c).length;
    c = c.replaceAll(RegExp('[\u060C\u061B]'), ' \u06DE ');

    if (dots) {
      // A stop that closes a paragraph needs no separator after it, and a run
      // of dots means "and so on to the end", so neither is touched.
      final stop = RegExp('(?<!\\.)\\.(?!\\.)');
      c = c.replaceAll(RegExp('(?<!\\.)\\.(?!\\.)(?=[ \\t\\r]*(\\n|\$))'), '');
      promoted += stop.allMatches(c).length;
      c = c.replaceAll(stop, ' \u06DE ');
    }

    // Two Qur'anic blocks with nothing between them still need a separator.
    final before = c;
    c = c.replaceAllMapped(
        RegExp('(\u0001\\d+\u0001)\\s*(?=\u0001\\d+\u0001)'),
        (m) => '${m[1]} \u06DE ');
    if (c != before) inserted++;

    // A mark cannot open a word: it was typed before its letter, not after.
    c = c.replaceAllMapped(
        RegExp('(\\s)([\u064B-\u0652\u0670]+)([\u0621-\u064A])'),
        (m) => '${m[1]}${m[3]}${m[2]}');
    // A mark with a space on both sides belongs to the word before it.
    c = c.replaceAllMapped(
        RegExp(' +([\u064B-\u0652\u0670]+)(?=\\s|\$)'), (m) => m[1]!);
    // A mark stranded after a separator belongs to nothing at all.
    c = c.replaceAllMapped(
        RegExp('(^|[\u06DE])\\s*[\u064B-\u0652\u0670]+'), (m) => m[1]!);

    // A comma next to a separator is the same pause written twice, and a run
    // of separators is still one pause. Collapse both before spacing them.
    // Spacing works on spaces alone: hizb al-ad3eya's paragraph breaks are
    // meaningful and must survive.
    c = c.replaceAll(RegExp('[\u06DE \t]*\u06DE[\u06DE \t]*'), '\u06DE');
    c = c.replaceAll(RegExp('[ \t]*\u06DE[ \t]*'), ' \u06DE ');
    c = c.replaceAll(RegExp('[ \t]*:[ \t]*'), ': ');
    c = c.replaceAllMapped(RegExp(r'\{\s*([^}]*?)\s*\}'), (m) => '{ ${m[1]} }');
    c = c.replaceAllMapped(RegExp(r'\(\s*([^)]*?)\s*\)'), (m) => '( ${m[1]} )');
    c = c.replaceAllMapped(RegExp(r'\[\s*([^\]]*?)\s*\]'), (m) => '[ ${m[1]} ]');
    c = c.replaceAll(RegExp(' {2,}'), ' ');
    // A separator that ends a paragraph separates nothing.
    c = c.replaceAll(RegExp('[ \\t]*\u06DE[ \\t]*(?=\\r?\\n)'), '');
    c = c.replaceAll(RegExp('^[\\s\u06DE]+'), '');
    c = c.replaceAll(RegExp('[\\s\u06DE]+\$'), '');
    c = c.trim();
    respaced++;

    for (var i = 0; i < kept.length; i++) {
      c = c.replaceAll('\u0001$i\u0001', kept[i]);
    }

    final marks = RegExp('\u06DE').allMatches(c).length;
    final left = RegExp('\u060C').allMatches(c).length;
    final bad = RegExp('[^ ]\u06DE|\u06DE[^ ]').allMatches(c).length;
    rows.add('${ids[b].padRight(18)} \u06DE $marks'.padRight(28) +
        (left == 0 ? '' : 'COMMAS LEFT: $left  ') +
        (bad == 0 ? 'spacing ok' : 'STILL WRONG: $bad'));

    text = text.substring(0, blocks[b].start) +
        "content: r'''$c'''" +
        text.substring(blocks[b].end);
  }

  if (apply) file.writeAsStringSync(text);
  for (final r in rows.reversed) {
    stdout.writeln(r);
  }
  stdout.writeln('\nlatin commas folded: $latin, commas turned into separators: '
      '$promoted, separators inserted in $inserted ahzab, respaced $respaced'
      '${apply ? " - applied" : " - dry run"}');
}
