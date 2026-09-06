import 'dart:convert';
import 'dart:io';

/// Downloads the whole mushaf once so detection can run offline.
Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(
      Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani-min'));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  client.close();

  final data = jsonDecode(body)['data'];
  final out = <Map<String, dynamic>>[];
  for (final surah in data['surahs']) {
    for (final ayah in surah['ayahs']) {
      out.add({
        'surah': surah['number'],
        'name': surah['name'],
        'ayah': ayah['numberInSurah'],
        'text': ayah['text'],
      });
    }
  }
  File('tool/quran.json').writeAsStringSync(jsonEncode(out));
  stdout.writeln('ayat saved: ${out.length}');
}
