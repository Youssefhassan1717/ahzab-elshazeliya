import 'dart:collection';
import 'package:flutter/widgets.dart';

/// Text elongated with tatweel (ـ) so wrapped lines fill the column the way
/// Arabic typesetting justifies, instead of stretching the spaces.
class KashidaText {
  final String text;

  /// Maps an index in the source string to its index in [text].
  final List<int> offsets;

  const KashidaText(this.text, this.offsets);

  int mapIndex(int sourceIndex) {
    if (offsets.isEmpty) return sourceIndex.clamp(0, text.length);
    if (sourceIndex <= 0) return 0;
    if (sourceIndex >= offsets.length) return text.length;
    return offsets[sourceIndex];
  }
}

class KashidaJustifier {
  KashidaJustifier._();

  static const String tatweel = '\u0640';

  /// Letters that connect to the letter after them.
  static const String _joinsForward =
      '\u0628\u062A\u062B\u062C\u062D\u062E\u0633\u0634\u0635\u0636\u0637'
      '\u0638\u0639\u063A\u0641\u0642\u0643\u0644\u0645\u0646\u0647\u064A'
      '\u0626\u0640';

  /// Lines filling less than this fraction of the column end a paragraph.
  static const double _minFillRatio = 0.55;
  static const int _maxPerSpot = 4;
  static const int _cacheLimit = 32;

  static final LinkedHashMap<_Key, KashidaText> _cache = LinkedHashMap();

  /// Lines touching [skipRanges] are left alone — they carry another font.
  static KashidaText resolve(
    String source,
    TextStyle style,
    double maxWidth, {
    List<(int, int)> skipRanges = const [],
  }) {
    if (source.length < 40 || maxWidth <= 60) return identity(source);
    final key = _Key(source, style.fontSize ?? 0, style.fontFamily ?? '',
        style.letterSpacing ?? 0, maxWidth.roundToDouble());
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final built = _build(source, style, maxWidth, skipRanges);
    _cache[key] = built;
    if (_cache.length > _cacheLimit) _cache.remove(_cache.keys.first);
    return built;
  }

  static KashidaText identity(String source) => KashidaText(source, const []);

  static KashidaText _build(
    String source,
    TextStyle style,
    double maxWidth,
    List<(int, int)> skipRanges,
  ) {
    final target = maxWidth - 4.0;
    if (target <= 0) return identity(source);

    final painter = TextPainter(
      text: TextSpan(text: source, style: style),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: maxWidth);

    final lineStarts = <int>[];
    int cursor = 0;
    final lineEnds = <int>[];
    while (cursor < source.length) {
      final range = painter.getLineBoundary(TextPosition(offset: cursor));
      final end = range.end > cursor ? range.end : source.length;
      lineStarts.add(cursor);
      lineEnds.add(end);
      if (end >= source.length) break;
      cursor = end;
      if (source.codeUnitAt(cursor) == 0x0A) cursor++;
    }
    painter.dispose();
    if (lineStarts.length < 2) return identity(source);

    // Source index -> number of tatweels inserted before it.
    final inserts = <int, int>{};

    for (int i = 0; i < lineStarts.length - 1; i++) {
      final start = lineStarts[i];
      var end = lineEnds[i];
      // A line ending on a newline already ends its paragraph.
      if (source.codeUnitAt(end - 1) == 0x0A) continue;
      while (end > start && source.codeUnitAt(end - 1) == 0x20) {
        end--;
      }
      if (end - start < 8) continue;
      if (_overlaps(skipRanges, start, end)) continue;

      final lineText = source.substring(start, end);
      final base = _measure(lineText, style);
      if (base >= target || base < target * _minFillRatio) continue;

      final spots = _spots(source, start, end);
      if (spots.isEmpty) continue;

      final unit = _measure(lineText + tatweel, style) - base;
      if (unit <= 0.2) continue;

      final cap = spots.length * _maxPerSpot;
      int count = ((target - base) / unit).floor().clamp(0, cap);
      if (count == 0) continue;

      double width = _measure(_apply(lineText, start, spots, count), style);
      for (int guard = 0; guard < 5 && width > target && count > 0; guard++) {
        count = (count * target / width).floor();
        width = _measure(_apply(lineText, start, spots, count), style);
      }
      for (int guard = 0; guard < 4 && count < cap; guard++) {
        final next = _measure(_apply(lineText, start, spots, count + 1), style);
        if (next > target) break;
        count++;
      }
      if (count <= 0) continue;

      inserts.addAll(_distribute(spots, count));
    }

    if (inserts.isEmpty) return identity(source);

    final buffer = StringBuffer();
    final offsets = List<int>.filled(source.length + 1, 0);
    int written = 0;
    for (int i = 0; i < source.length; i++) {
      final extra = inserts[i];
      if (extra != null) {
        buffer.write(tatweel * extra);
        written += extra;
      }
      offsets[i] = written;
      buffer.writeCharCode(source.codeUnitAt(i));
      written++;
    }
    offsets[source.length] = written;
    return KashidaText(buffer.toString(), offsets);
  }

  static bool _overlaps(List<(int, int)> ranges, int start, int end) {
    for (final (s, e) in ranges) {
      if (s < end && e > start) return true;
    }
    return false;
  }

  /// Source indices where a tatweel fits: between a forward-joining letter
  /// (plus its marks) and a letter that accepts a connection before it.
  static List<int> _spots(String source, int start, int end) {
    final spots = <int>[];
    for (int i = start; i < end; i++) {
      if (!_joinsForward.contains(source[i])) continue;
      int j = i + 1;
      while (j < end && _isMark(source.codeUnitAt(j))) {
        j++;
      }
      if (j >= end) break;
      if (!_joinsBackward(source.codeUnitAt(j))) continue;
      spots.add(j);
    }
    return spots;
  }

  static bool _isMark(int c) =>
      (c >= 0x064B && c <= 0x065F) || c == 0x0670 || (c >= 0x06D6 && c <= 0x06ED);

  static bool _joinsBackward(int c) => c >= 0x0622 && c <= 0x064A;

  /// Spreads [count] tatweels as evenly as possible over [spots].
  static Map<int, int> _distribute(List<int> spots, int count) {
    final result = <int, int>{};
    if (spots.isEmpty || count <= 0) return result;
    final each = count ~/ spots.length;
    var remainder = count % spots.length;
    final step = remainder > 0 ? spots.length / remainder : 0.0;
    double next = 0;
    for (int i = 0; i < spots.length; i++) {
      var amount = each;
      if (remainder > 0 && i >= next) {
        amount++;
        remainder--;
        next += step;
      }
      if (amount > 0) result[spots[i]] = amount;
    }
    return result;
  }

  static String _apply(
      String lineText, int lineStart, List<int> spots, int count) {
    if (count <= 0) return lineText;
    final amounts = _distribute(spots, count);
    final buffer = StringBuffer();
    for (int i = 0; i < lineText.length; i++) {
      final extra = amounts[lineStart + i];
      if (extra != null) buffer.write(tatweel * extra);
      buffer.write(lineText[i]);
    }
    return buffer.toString();
  }

  static double _measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _Key {
  final String source;
  final double fontSize;
  final String fontFamily;
  final double letterSpacing;
  final double width;

  const _Key(this.source, this.fontSize, this.fontFamily, this.letterSpacing,
      this.width);

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.fontSize == fontSize &&
      other.width == width &&
      other.letterSpacing == letterSpacing &&
      other.fontFamily == fontFamily &&
      other.source == source;

  @override
  int get hashCode => Object.hash(source.length, fontSize, width, fontFamily);
}
