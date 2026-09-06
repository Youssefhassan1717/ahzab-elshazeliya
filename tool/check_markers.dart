import 'dart:io';

void main() {
  final t = File('lib/data/ahzab_data.dart').readAsStringSync();
  int count(String s) => RegExp(RegExp.escape(s)).allMatches(t).length;
  stdout.writeln('Q markers : ${count('\u00A7Q\u00A7')}');
  stdout.writeln('B markers : ${count('\u00A7B\u00A7')}');
  stdout.writeln('SECTION   : ${count('\u00A7SECTION\u00A7')}');
  stdout.writeln('nested QQ : ${count('\u00A7Q\u00A7\u00A7Q\u00A7')}');
  stdout.writeln('nested BB : ${count('\u00A7B\u00A7\u00A7B\u00A7')}');
  final blocks = RegExp('\u00A7Q\u00A7(.+?)\\|(.+?)\u00A7Q\u00A7', dotAll: true)
      .allMatches(t);
  stdout.writeln('Q blocks  : ${blocks.length}');
}
