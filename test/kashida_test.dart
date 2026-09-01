import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahzab_app/core/kashida.dart';

void main() {
  const style = TextStyle(fontSize: 20, height: 1.9);

  test('inserts tatweel and keeps the source recoverable', () {
    final source = List.filled(40, 'اللهم صل على سيدنا محمد وعلى اله وصحبه').join(' ');
    final result = KashidaJustifier.resolve(source, style, 320);

    expect(result.text.length, greaterThan(source.length));
    expect(result.text.replaceAll('\u0640', ''), source.replaceAll('\u0640', ''));

    for (int i = 0; i <= source.length; i += 17) {
      final mapped = result.mapIndex(i);
      expect(mapped, inInclusiveRange(0, result.text.length));
    }
  });

  test('short text is left alone', () {
    const short = 'اللهم صل';
    final result = KashidaJustifier.resolve(short, style, 320);
    expect(result.text, short);
  });

  test('mapped ranges still bracket the same word', () {
    final source =
        '${List.filled(20, 'ربنا اتنا في الدنيا حسنة وفي الاخرة حسنة').join(' ')} فاصلة';
    final needle = source.indexOf('فاصلة');
    final result = KashidaJustifier.resolve(source, style, 300);
    final start = result.mapIndex(needle);
    final end = result.mapIndex(needle + 'فاصلة'.length);
    expect(result.text.substring(start, end).replaceAll('\u0640', ''), 'فاصلة');
  });
}
