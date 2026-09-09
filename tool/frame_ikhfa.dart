import 'dart:io';

/// Frames the four repeated passages in hizb al-ikhfa that were never marked,
/// which is why they alone stayed the colour of ordinary text.
void main(List<String> args) {
  final apply = args.contains('--apply');
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final b = ids.indexOf('ikhfa');
  var c = blocks[b].group(1)!;

  // The brackets around it are the book's; the app marks a repeat itself.
  final shahat = RegExp(r'\[\s*([^\]]*?)\s*\]\s*(?=\{)');
  if (shahat.hasMatch(c)) {
    c = c.replaceFirstMapped(
        shahat, (m) => '\u00A7B\u00A7${m[1]}\u00A7b\u00A7 ');
    stdout.writeln('framed: the bracketed passage');
  }

  // The rest are counted backwards in words from their label.
  for (final words in [5, 12]) {
    if (!_frameWords(c, words, (out) => c = out)) {
      stdout.writeln('MISS: no loose label needing $words words');
    } else {
      stdout.writeln('framed: $words words');
    }
  }

  // One repeat is a whole Qur'anic block. The reference may not contain a
  // marker, or the match can start at some earlier block's closing marker.
  final quran = RegExp(
      '(\u00A7Q\u00A7[^|\u00A7]*\\|[^\u00A7]*\u00A7Q\u00A7)(\\s*)(?=\\{)',
      dotAll: true);
  final before = c;
  c = c.replaceFirstMapped(
      quran, (m) => '\u00A7B\u00A7${m[1]}\u00A7b\u00A7${m[2]}');
  stdout.writeln(c == before ? 'MISS: no loose Qur\'anic repeat' : 'framed: a Qur\'anic block');

  text = text.substring(0, blocks[b].start) +
      "content: r'''$c'''" +
      text.substring(blocks[b].end);
  if (apply) file.writeAsStringSync(text);
  stdout.writeln(apply ? 'applied' : 'dry run');
}

/// Wraps the [words] words that run up to the first still-unframed label.
bool _frameWords(String c, int words, void Function(String) out) {
  for (final m in RegExp(r'\{[^}]*\}').allMatches(c)) {
    final head = c.substring(0, m.start).trimRight();
    if (head.endsWith('\u00A7b\u00A7') || head.endsWith('\u00A7Q\u00A7')) continue;
    final found =
        RegExp('[\u0621-\u065F\u0670]+').allMatches(head).toList();
    if (found.length < words) continue;
    final start = found[found.length - words].start;
    out(c.substring(0, start) +
        '\u00A7B\u00A7' +
        head.substring(start) +
        '\u00A7b\u00A7 ' +
        c.substring(m.start));
    return true;
  }
  return false;
}
