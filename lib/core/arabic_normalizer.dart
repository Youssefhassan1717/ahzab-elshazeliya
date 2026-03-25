/// Normalizes Arabic text for forgiving search.
///
/// - Strips diacritics (tashkeel): َ ً ُ ٌ ِ ٍ ْ ّ ـ
/// - Normalizes hamza forms: أ إ آ → ا, ؤ → و, ئ → ي
/// - Normalizes taa marbuta: ة → ه
/// - Trims and collapses whitespace
String normalizeArabic(String text) {
  // Remove Arabic diacritics (tashkeel) and tatweel
  var result = text.replaceAll(_diacriticsPattern, '');

  // Normalize hamza on alef forms → bare alef
  result = result.replaceAll(_alefVariants, 'ا');

  // Normalize hamza on waw → waw
  result = result.replaceAll('ؤ', 'و');

  // Normalize hamza on yaa → yaa
  result = result.replaceAll('ئ', 'ي');

  // Normalize taa marbuta → haa
  result = result.replaceAll('ة', 'ه');

  return result;
}

// Unicode ranges for Arabic diacritics:
// U+064B FATHATAN .. U+065F WAVY HAMZA BELOW
// U+0670 SUPERSCRIPT ALEF
// U+0640 TATWEEL
final _diacriticsPattern = RegExp(r'[\u064B-\u065F\u0670\u0640]');

// أ (U+0623), إ (U+0625), آ (U+0622), ٱ (U+0671)
final _alefVariants = RegExp(r'[أإآٱ]');

/// Finds all match ranges in [original] text where the normalized form
/// matches [normalizedQuery].
///
/// Returns a list of (start, end) pairs in the ORIGINAL text coordinates.
List<(int, int)> findNormalizedMatches(String original, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return [];

  final matches = <(int, int)>[];

  // Build a mapping: for each char in original, its index in normalized
  // We need the reverse: for each position in normalized, the original position
  final normChars = <int>[]; // original indices that survived normalization
  final normalized = StringBuffer();

  for (int i = 0; i < original.length; i++) {
    final ch = original[i];
    // Check if this char is a diacritic (would be removed)
    if (_diacriticsPattern.hasMatch(ch)) continue;

    // Apply char-level normalization
    String normCh = ch;
    if (_alefVariants.hasMatch(ch)) {
      normCh = 'ا';
    } else if (ch == 'ؤ') {
      normCh = 'و';
    } else if (ch == 'ئ') {
      normCh = 'ي';
    } else if (ch == 'ة') {
      normCh = 'ه';
    }

    normalized.write(normCh);
    normChars.add(i);
  }

  final normStr = normalized.toString();

  int searchFrom = 0;
  while (searchFrom <= normStr.length - normalizedQuery.length) {
    final normIdx = normStr.indexOf(normalizedQuery, searchFrom);
    if (normIdx < 0) break;

    // Map back to original indices
    final origStart = normChars[normIdx];
    final normEnd = normIdx + normalizedQuery.length - 1;
    // The end in original is the char at normEnd, plus any trailing diacritics
    int origEnd = normChars[normEnd] + 1;
    // Include any diacritics that follow the last matched char in original
    while (origEnd < original.length && _diacriticsPattern.hasMatch(original[origEnd])) {
      origEnd++;
    }

    matches.add((origStart, origEnd));
    searchFrom = normIdx + 1; // allow overlapping if needed
  }

  return matches;
}

/// Finds the best match for a snippet preview — prefers word-boundary matches
/// over substring matches within longer words.
///
/// Scoring (higher = better):
/// - 30: standalone word (space/start before AND space/end after)
/// - 20: match at word start, or right after "ال" article at word start
/// - 10: match at word end
/// - 0: substring within a word
///
/// Returns null if no match found.
(int, int)? findBestSnippetMatch(String original, String normalizedQuery) {
  final matches = findNormalizedMatches(original, normalizedQuery);
  if (matches.isEmpty) return null;

  (int, int)? bestMatch;
  int bestScore = -1;

  for (final match in matches) {
    final (start, end) = match;
    int score = 0;

    final atStart = start == 0 || original[start - 1] == ' ' || original[start - 1] == '\n';
    final atEnd = end >= original.length || original[end] == ' ' || original[end] == '\n';

    // Check for Arabic "ال" article prefix: if "ال" is right before the match
    // and that "ال" is at a word boundary
    final afterAlPrefix = start >= 2 &&
        original[start - 1] == 'ل' &&
        (original[start - 2] == 'ا' || _alefVariants.hasMatch(original[start - 2])) &&
        (start - 2 == 0 || original[start - 3] == ' ' || original[start - 3] == '\n');

    if (atStart || afterAlPrefix) {
      score += 20;
    }
    if (atEnd) {
      score += 10;
    }

    if (score > bestScore) {
      bestScore = score;
      bestMatch = match;
    }

    // Perfect standalone word match
    if (score >= 30) break;
  }

  return bestMatch ?? matches.first;
}
