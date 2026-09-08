import 'dart:io';

/// Brings every hizb to one house style: a single separator, no stray quotes,
/// no line breaks mid-sentence, even spacing.
///
/// hizb al-ad3eya is left alone - it is a collection of separate du'as with
/// headings and deliberate paragraph breaks, not a continuous litany.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync().replaceAll('\uFEFF', '');
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  var quotes = 0, dots = 0, pipes = 0, breaks = 0, runs = 0, spacing = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var c = blocks[b].group(1)!.replaceAll('\r', '');
    if (ids[b] == 'ad3eya') {
      text = _splice(text, blocks[b], c);
      continue;
    }

    // The Qur'an blocks carry their own pipe and spacing; keep them out of this.
    final kept = <String>[];
    c = c.replaceAllMapped(
        RegExp('\u00A7Q\u00A7.*?\u00A7Q\u00A7', dotAll: true), (m) {
      kept.add(m.group(0)!);
      return '\u0001${kept.length - 1}\u0001';
    });

    if (ids[b] == 'nasr') {
      c = c.replaceAll(
          RegExp('\u062A\u064E\u0645\u064E\u0651[^\u06DE\u0001]*'
              '\u0627\u0644\u0639\u064E\u0627\u0644\u064E\u0645\u0650\u064A\u0646\u064E\\s*\$'),
          '');
    }

    breaks += RegExp(r'\n+').allMatches(c).length;
    c = c.replaceAll(RegExp(r'\n+'), ' ');

    quotes += RegExp('["\u201C\u201D]').allMatches(c).length;
    c = c.replaceAll(RegExp('["\u201C\u201D]'), '');

    // A single full stop is this book's phrase separator; a run of them means
    // "and so on to the end of the sura", so those stay.
    c = c.replaceAllMapped(RegExp(r'(?<!\.)\.(?!\.)'), (_) {
      dots++;
      return ' \u06DE ';
    });
    pipes += RegExp(r'\|').allMatches(c).length;
    c = c.replaceAll('|', ' \u06DE ');

    final before = c;
    c = c.replaceAll(RegExp('\u06DE(\\s*\u06DE)+'), '\u06DE');
    if (c != before) runs++;

    c = c.replaceAll(RegExp('\\s*\u06DE\\s*'), ' \u06DE ');
    c = c.replaceAllMapped(RegExp(r'\{\s*([^}]*?)\s*\}'), (m) => '{ ${m[1]} }');
    c = c.replaceAll(RegExp(' {2,}'), ' ');
    c = c.replaceAll(RegExp('^\\s*\u06DE\\s*'), '');
    c = c.replaceAll(RegExp('\\s*\u06DE\\s*\$'), '');
    c = c.trim();
    spacing++;

    for (var i = 0; i < kept.length; i++) {
      c = c.replaceAll('\u0001$i\u0001', kept[i]);
    }
    text = _splice(text, blocks[b], c);
  }

  // The count that goes with this phrase was left as plain text.
  const arbaa = '\u0644\u0627\u064E \u062D\u0640\u064E\u0648\u0652\u0644\u064E '
      '\u0648\u064E\u0644\u0627\u064E \u0642\u0640\u064F\u0648\u064E\u0651\u0629\u064E '
      '\u0625\u0650\u0644\u0627\u064E\u0651 \u0628\u0650\u0627\u0644\u0644\u0647\u0650 '
      '\u0627\u0644\u0640\u0639\u064E\u0640\u0644\u0649\u0650\u0651 '
      '\u0627\u0644\u0639\u064E\u0638\u0650\u0640\u064A\u0640\u0652\u0645\u0650';
  const four = '\u0623\u0631\u0652\u0628\u064E\u0639\u064E\u0640\u0627\u064B';
  if (text.contains('$arbaa $four')) {
    text = text.replaceFirst(
        '$arbaa $four', '\u00A7B\u00A7$arbaa\u00A7b\u00A7 { $four }');
  } else {
    stdout.writeln('MISS: the arbaan phrase was not found');
  }

  if (apply) file.writeAsStringSync(text);
  stdout.writeln('quotes removed: $quotes, dots converted: $dots, '
      'pipes converted: $pipes, line breaks flattened: $breaks, '
      'doubled runs collapsed in $runs ahzab, respaced $spacing ahzab'
      '${apply ? " - applied" : " - dry run"}');
}

String _splice(String text, RegExpMatch block, String content) =>
    text.substring(0, block.start) +
    "content: r'''$content'''" +
    text.substring(block.end);
