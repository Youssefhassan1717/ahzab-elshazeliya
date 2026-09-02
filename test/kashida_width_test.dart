import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahzab_app/core/kashida.dart';
import 'package:ahzab_app/data/ahzab_data.dart';
import 'package:ahzab_app/screens/detail/widgets/content_body.dart';

/// The column a phone renders at, roughly.
const double _width = 360;
const _style = TextStyle(fontFamily: 'ScheherazadeNew', fontSize: 24, height: 1.9);

final _sectionPattern = RegExp(r'§SECTION§.+?§SECTION§');

double _widthOf(String s) {
  final p = TextPainter(
    text: TextSpan(text: s, style: _style),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  final w = p.width;
  p.dispose();
  return w;
}

void main() {
  test('no word is stretched wider than the column', () {
    for (final part in allParts) {
      final source =
          ContentBody.stripMarkup(part.content.replaceAll(_sectionPattern, ' '));
      final result = KashidaJustifier.resolve(source, _style, _width);
      for (final token in result.text.split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;
        expect(_widthOf(token), lessThanOrEqualTo(_width),
            reason: 'hizb ${part.id} produced an over-wide token: $token');
      }
    }
  });
}
