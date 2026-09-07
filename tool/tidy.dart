import 'dart:io';

/// Tidies the hizb texts: words broken by a stray space, and the book's own
/// brackets where they now sit on top of a marker the app draws itself.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  var joined = 0, unwrapped = 0, dropped = 0, relabelled = 0, separators = 0;

  for (var b = blocks.length - 1; b >= 0; b--) {
    var c = blocks[b].group(1)!;

    // A waw is a prefix; it never stands alone as its own word.
    c = c.replaceAllMapped(
        RegExp('(\\s\u0648[\u064B-\u0652]?) ([\u0621-\u064A])'), (m) {
      joined++;
      return '${m.group(1)}${m.group(2)}';
    });

    for (final fix in _splitWords.entries) {
      if (c.contains(fix.key)) {
        c = c.replaceAll(fix.key, fix.value);
        joined++;
      }
    }

    // An ayah number left behind next to the ayah the app now numbers itself.
    c = c.replaceAllMapped(
        RegExp('(\u00A7Q\u00A7)\\s*\uFD3F[\u0660-\u0669]+\uFD3E'), (m) {
      dropped++;
      return m.group(1)!;
    });

    // A bracket wrapped round a passage the app already brackets itself.
    c = c.replaceAllMapped(
        RegExp('[(\uFD3F]\\s*(\u00A7Q\u00A7.*?\u00A7Q\u00A7)\\s*[)\uFD3E]',
            dotAll: true), (m) {
      unwrapped++;
      return m.group(1)!;
    });
    c = c.replaceAllMapped(
        RegExp('\u00A7B\u00A7\\s*\\(\\s*(.*?)\\s*\\)\\s*\u00A7b\u00A7',
            dotAll: true), (m) {
      unwrapped++;
      return '\u00A7B\u00A7${m.group(1)}\u00A7b\u00A7';
    });

    // A repeat count in the book's round brackets, so it is drawn like the rest.
    c = c.replaceAllMapped(
        RegExp('\\(\\s*(\u062B\u0644\u0627\u062B\u0627\u064B|'
            '\u0633\u0628\u0639\u0627\u064B)\\s*\\)'), (m) {
      relabelled++;
      return '{ ${m.group(1)} }';
    });

    // One separator across the whole book: the rub-el-hizb mark that hizb
    // al-Bahr already uses, in place of asterisks and stray pipes.
    c = c.replaceAllMapped(RegExp(r'\s*\*\s*'), (_) {
      separators++;
      return ' \u06DE ';
    });
    c = c.replaceAllMapped(RegExp(r'\s+\|\s+'), (_) {
      separators++;
      return ' \u06DE ';
    });

    text = text.substring(0, blocks[b].start) +
        "content: r'''$c'''" +
        text.substring(blocks[b].end);
  }

  if (apply) file.writeAsStringSync(text);
  stdout.writeln('words joined: $joined, brackets unwrapped: $unwrapped, '
      'stray numbers dropped: $dropped, labels normalised: $relabelled, '
      'separators unified: $separators'
      '${apply ? " - applied" : " - dry run"}');
}

/// Words the book splits with a space in the middle.
const _splitWords = <String, String>{
  '\u0627\u0644\u0639\u0650\u0640\u0632\u064E\u0651 \u0629 \u0650':
      '\u0627\u0644\u0639\u0650\u0632\u064E\u0651\u0629\u0650',
  '\u0623\u064E \u064A\u0640\u064F\u0651\u0647\u0640\u064E\u0627':
      '\u0623\u064E\u064A\u064F\u0651\u0647\u064E\u0627',
  '\u0627\u0644\u0645\u064E\u0644\u0627\u064E \u0626\u0650\u0643\u064E\u0629\u064F':
      '\u0627\u0644\u0645\u064E\u0644\u0627\u064E\u0626\u0650\u0643\u064E\u0629\u064F',
  '\u0648\u064E\u0633\u0644\u0627 \u0645\u064C':
      '\u0648\u064E\u0633\u0644\u0627\u0645\u064C',
  '\u0633\u064E\u0644\u0627 \u0645\u064C':
      '\u0633\u064E\u0644\u0627\u0645\u064C',
};
