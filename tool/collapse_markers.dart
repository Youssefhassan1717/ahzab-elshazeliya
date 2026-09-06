import 'dart:io';

void main() {
  final file = File('lib/data/ahzab_data.dart');
  var t = file.readAsStringSync();
  const m = '\u00A7B\u00A7';
  var before = RegExp(RegExp.escape(m)).allMatches(t).length;
  while (t.contains(m + m)) {
    t = t.replaceAll(m + m, m);
  }
  file.writeAsStringSync(t);
  final after = RegExp(RegExp.escape(m)).allMatches(t).length;
  stdout.writeln('markers $before -> $after');
}
