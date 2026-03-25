// Quick test to debug the snippet matching
import 'dart:io';

// Copy of normalizer logic
final _diacriticsPattern = RegExp(r'[\u064B-\u065F\u0670\u0640]');
final _alefVariants = RegExp(r'[أإآٱ]');

String normalizeArabic(String text) {
  var result = text.replaceAll(_diacriticsPattern, '');
  result = result.replaceAll(_alefVariants, 'ا');
  result = result.replaceAll('ؤ', 'و');
  result = result.replaceAll('ئ', 'ي');
  result = result.replaceAll('ة', 'ه');
  return result;
}

List<(int, int)> findNormalizedMatches(String original, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return [];
  final matches = <(int, int)>[];
  final normChars = <int>[];
  final normalized = StringBuffer();

  for (int i = 0; i < original.length; i++) {
    final ch = original[i];
    if (_diacriticsPattern.hasMatch(ch)) continue;
    String normCh = ch;
    if (_alefVariants.hasMatch(ch)) normCh = 'ا';
    else if (ch == 'ؤ') normCh = 'و';
    else if (ch == 'ئ') normCh = 'ي';
    else if (ch == 'ة') normCh = 'ه';
    normalized.write(normCh);
    normChars.add(i);
  }

  final normStr = normalized.toString();
  int searchFrom = 0;
  while (searchFrom <= normStr.length - normalizedQuery.length) {
    final normIdx = normStr.indexOf(normalizedQuery, searchFrom);
    if (normIdx < 0) break;
    final origStart = normChars[normIdx];
    final normEnd = normIdx + normalizedQuery.length - 1;
    int origEnd = normChars[normEnd] + 1;
    while (origEnd < original.length && _diacriticsPattern.hasMatch(original[origEnd])) {
      origEnd++;
    }
    matches.add((origStart, origEnd));
    searchFrom = normIdx + 1;
  }
  return matches;
}

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
    final afterAlPrefix = start >= 2 &&
        original[start - 1] == 'ل' &&
        (original[start - 2] == 'ا' || _alefVariants.hasMatch(original[start - 2])) &&
        (start - 2 == 0 || original[start - 3] == ' ' || original[start - 3] == '\n');
    if (atStart || afterAlPrefix) score += 20;
    if (atEnd) score += 10;
    if (score > bestScore) { bestScore = score; bestMatch = match; }
    if (score >= 30) break;
  }
  return bestMatch ?? matches.first;
}

void main() {
  // Test: searching "حمد" should find "الحمد" not "محمد"
  final content = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ ثُمَّ الحَمْدُ لِلَّهِ رَبِّ العَالَمِينَ';
  
  // Test 1: "حمد" - should prefer "الحمد" but first match might be "محمد"  
  test(content, 'حمد');
  
  // Test 2: "الرحمن" 
  test(content, 'الرحمن');
  
  // Test 3: "نور" in text with "منصور" before "نور"
  final content2 = 'قال الشيخ منصور بن علي ثم ذكر النور المبين';
  test(content2, 'نور');
}

void test(String content, String query) {
  final normalizedQuery = normalizeArabic(query);
  print('\n=== Query: "$query" (normalized: "$normalizedQuery") ===');
  
  final cleanContent = content.replaceAll(RegExp(r'§SECTION§.+?§SECTION§'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final matches = findNormalizedMatches(cleanContent, normalizedQuery);
  
  print('All ${matches.length} matches:');
  for (int i = 0; i < matches.length; i++) {
    final (start, end) = matches[i];
    final matchText = cleanContent.substring(start, end);
    final atWordStart = start == 0 || cleanContent[start - 1] == ' ';
    final atWordEnd = end >= cleanContent.length || cleanContent[end] == ' ';
    print('  [$i] "$matchText" wordStart=$atWordStart wordEnd=$atWordEnd');
  }
  
  final best = findBestSnippetMatch(cleanContent, normalizedQuery);
  if (best != null) {
    final (start, end) = best;
    final matchText = cleanContent.substring(start, end);
    final ctxStart = (start - 20).clamp(0, cleanContent.length);
    final ctxEnd = (end + 20).clamp(0, cleanContent.length);
    print('  BEST: "$matchText" context="...${cleanContent.substring(ctxStart, ctxEnd)}..."');
  }
}
