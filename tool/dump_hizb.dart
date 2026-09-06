import 'dart:io';

void main(List<String> args) {
  final file = File('lib/data/ahzab_data.dart');
  final text = file.readAsStringSync();
  final blocks = RegExp(r"id: '([a-z0-9_]+)'", dotAll: true).allMatches(text).toList();
  final contents =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();
  final want = args.isEmpty ? 'barr' : args.first;
  for (var i = 0; i < blocks.length; i++) {
    if (blocks[i].group(1) != want) continue;
    File('_dump.txt').writeAsStringSync(contents[i].group(1)!);
    stdout.writeln('wrote ${contents[i].group(1)!.length} chars');
  }
}
