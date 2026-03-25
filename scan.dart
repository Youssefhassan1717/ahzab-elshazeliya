import 'dart:io';

void main() {
  final content = File('lib/data/ahzab_data.dart').readAsStringSync();
  final lines = content.split('\n');
  String currentHizb = '';
  final pattern = RegExp(r' {2,}');
  int total = 0;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final hizbMatch = RegExp(r"id: '(\w+)'").firstMatch(line);
    if (hizbMatch != null) currentHizb = hizbMatch.group(1)!;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('import ') || trimmed.startsWith('final ') ||
        trimmed.startsWith('const ') || trimmed.startsWith('id:') ||
        trimmed.startsWith('title:') || trimmed.startsWith('subtitle:') ||
        trimmed.startsWith('content:') || trimmed.startsWith(');') ||
        trimmed.startsWith('],') || trimmed == '];' || trimmed == ']') continue;
    if (currentHizb == 'bahr') continue;
    final matches = pattern.allMatches(line).toList();
    for (final m in matches) {
      if (m.start < 5) continue;
      final start = (m.start - 20).clamp(0, line.length);
      final end = (m.end + 20).clamp(0, line.length);
      print('L${i+1} [$currentHizb] [${m.end-m.start}sp]: ...${line.substring(start, end).replaceAll('\r','')}...');
      total++;
    }
  }
  print('\nTotal: $total');
}
