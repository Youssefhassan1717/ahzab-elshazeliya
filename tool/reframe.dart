import 'dart:io';

/// Re-frames a passage: everything from [start] to [end] becomes one repeated
/// block, dropping any framing markers that were already inside it.
class _Job {
  final String hizb;
  final String start;
  final String end;
  final String? drop;
  const _Job(this.hizb, this.start, this.end, {this.drop});
}

const marker = '\u00A7B\u00A7';

const jobs = <_Job>[
  // The whole invocation is said three times, not just its last sentence.
  _Job('barr', '\u064A\u064E\u0627 \u0623\u064E\u0644\u0644\u0651\u0647\u064F \u064A\u064E\u0627 \u0639\u064E\u0644\u0650\u0649\u064F\u0651 \u064A\u064E\u0627 \u0639\u064E\u0638\u0650\u064A\u0645\u064F \u064A\u064E\u0627 \u062D\u064E\u0644\u0650\u064A\u0645\u064F',
      '\u0642\u064E\u062F\u0650\u064A\u0631\u064C \u064A\u064E\u0627 \u0627\u0644\u0644\u0651\u0647\u064F'),
  _Job('barr', '\u0648\u064E\u0627\u062C\u0652\u0639\u064E\u0644\u0652 \u064A\u064E\u062F\u064E\u0643\u064E \u0645\u064E\u0628\u0652\u0633\u064F\u0648\u0637\u064E\u0629\u064B',
      '\u064A\u064E\u0627 \u0646\u0650\u0639\u0652\u0645\u064E \u0627\u0644\u0645\u062C\u0650\u064A\u0628\u064F'),
  _Job('barr', '\u0644\u0627\u064E \u0625\u0644\u0647\u064E \u0625\u0644\u0627\u0650 \u0623\u064E\u0646\u0652\u062A\u064E \u0633\u064F\u0628\u0652\u062D\u064E\u0627\u0646\u064E\u0643\u064E',
      '\u0645\u0650\u0646\u064E \u0627\u0644\u0638\u064E\u0651\u0627\u0644\u0650\u0645\u064A\u0646\u064E',
      drop: '\u0648\u064E\u0623\u064E\u0646\u064E\u0651 \u0630\u064E\u0644\u0650\u0643\u064E \u0644\u064E\u0648\u064E\u0627\u0642\u0650\u0639\u064C'),
];

void main() {
  final file = File('lib/data/ahzab_data.dart');
  var text = file.readAsStringSync();
  final ids =
      RegExp(r"id: '([a-z0-9_]+)'").allMatches(text).map((m) => m.group(1)!).toList();
  final blocks =
      RegExp(r"content: r'''(.*?)'''", dotAll: true).allMatches(text).toList();

  var done = 0;
  for (var b = blocks.length - 1; b >= 0; b--) {
    var content = blocks[b].group(1)!;
    var touched = false;
    for (final job in jobs.where((j) => j.hizb == ids[b])) {
      if (job.drop != null) {
        content = content.replaceAll(marker + job.drop!, job.drop!);
      }
      final s = content.indexOf(job.start);
      if (s < 0) {
        stdout.writeln('MISS start: ${job.start}');
        continue;
      }
      final e = content.indexOf(job.end, s);
      if (e < 0) {
        stdout.writeln('MISS end: ${job.end}');
        continue;
      }
      final stop = e + job.end.length;
      final inner = content.substring(s, stop).replaceAll(marker, '');
      content = content.substring(0, s) + marker + inner + marker + content.substring(stop);
      touched = true;
      done++;
    }
    if (!touched) continue;
    text = text.substring(0, blocks[b].start) +
        "content: r'''$content'''" +
        text.substring(blocks[b].end);
  }

  file.writeAsStringSync(text);
  stdout.writeln('reframed: $done');
}
