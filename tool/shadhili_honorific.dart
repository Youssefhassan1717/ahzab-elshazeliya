import 'dart:io';

/// In the muqaddima, the Shaykh Abu al-Hasan al-Shadhili should be followed by
/// رضي الله عنه, not رحمه الله. Other scholars keep رحمه الله, so each rule is
/// anchored to the words that name him.
///
///   dart run tool/shadhili_honorific.dart [--apply]
void main(List<String> args) {
  final apply = args.contains('--apply');
  final file = File('lib/data/muqaddima.dart');
  var text = file.readAsStringSync();

  const rahima = 'رَحِمَهُ اللَّهُ';
  const radiya = 'رَضِيَ اللَّهُ عَنْهُ';

  // Anchored so only the Shaykh is touched. The '«كُلُّ' rule catches the one
  // saying introduced without a leading و.
  final rules = <String, String>{
    'الشَّاذِلِيِّ $rahima': 'الشَّاذِلِيِّ $radiya',
    'أَبُو الحَسَنِ $rahima': 'أَبُو الحَسَنِ $radiya',
    'أَبَا الحَسَنِ $rahima': 'أَبَا الحَسَنِ $radiya',
    'أَبِي الحَسَنِ $rahima': 'أَبِي الحَسَنِ $radiya',
    'قَوْلُهُ $rahima: «كُلُّ': 'قَوْلُهُ $radiya: «كُلُّ',
    'وَقَوْلُهُ $rahima:': 'وَقَوْلُهُ $radiya:',
  };

  final before = rahima.allMatches(text).length;
  var changed = 0;

  for (final rule in rules.entries) {
    final hits = rule.key.allMatches(text).length;
    if (hits == 0) continue;
    changed += hits;
    stdout.writeln('$hits  ${rule.key}');
    if (apply) text = text.replaceAll(rule.key, rule.value);
  }

  stdout.writeln('---');
  stdout.writeln('رحمه الله before      : $before');
  stdout.writeln('rewritten to رضي الله عنه: $changed');
  stdout.writeln('left for other scholars : ${before - changed}');

  if (apply) {
    file.writeAsStringSync(text);
    stdout.writeln('applied');
  } else {
    stdout.writeln('dry run — pass --apply to write');
  }
}
