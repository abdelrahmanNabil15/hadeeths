// Writes `assets/quran/mushaf-madinah-lines.txt`: every line of the 15-line Madinah mushaf
// (King Fahd Complex, 1421H print, "V2"), word for word, in the King Fahd Complex's own Uthmani
// Hafs text — the text the bundled KFGQPC HAFS Uthmanic Script font is drawn for.
//
// Source: the public Quran.com API v4 (`/verses/by_page/<n>?mushaf=1&words=true`), which gives for
// every word its `text_qpc_hafs`, its `v2_page` and its `line_v2`. Fetched 2026-11-21.
//
// Run:
//   dart run tool/build_mushaf_lines.dart <cache-dir>
//
// Pages already in <cache-dir> (one `NNN.json` per page) are not fetched again. The API gives no
// rows for the lines that hold a sura's name or its basmala; they are the page's empty lines, and
// each one is given to the sura that starts right after it. Nothing is written unless every check
// passes: 604 pages, 15 lines each (8 on pages 1 and 2), every line used exactly once, and every
// sura with the same number of verses as the bundled Tanzil text.
//
// Output, one line of the mushaf per line of the file, `#` lines are comments:
//   page|line|s|<sura>                     the sura's name
//   page|line|b|<text>                     the basmala
//   page|line|a|<seg>;<seg>;...            verses; seg = sura:verse:<e|->:<words>
// where `e` means the verse ends on this line (its number follows its last word). A verse's
// number that the print wraps onto the next line by itself is a seg with no words.
import 'dart:convert';
import 'dart:io';

const _pageCount = 604;

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/build_mushaf_lines.dart <cache-dir>');
    exit(64);
  }
  final cache = Directory(args.single)..createSync(recursive: true);
  final client = HttpClient()..userAgent = 'mushaf-lines-builder';
  final pages = <int, List<Map<String, dynamic>>>{};
  for (var page = 1; page <= _pageCount; page++) {
    final file = File('${cache.path}/${page.toString().padLeft(3, '0')}.json');
    if (!file.existsSync()) {
      file.writeAsStringSync(jsonEncode(await _fetch(client, page)));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    pages[page] = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
  }
  client.close();

  // Every verse once, in order (a verse that runs onto the next page is listed on both).
  final verses = <String, List<Map<String, dynamic>>>{};
  for (var page = 1; page <= _pageCount; page++) {
    for (final verse in pages[page]!) {
      verses.putIfAbsent(
        verse['k'] as String,
        () => (verse['w'] as List).cast<Map<String, dynamic>>(),
      );
    }
  }

  // Every slot (page, line) and what fills it. Each word goes where the API puts it.
  final lineSegs = <(int, int), List<String>>{};
  final lineEnds = <(int, int), Set<String>>{};
  String? basmala;
  final verseCounts = <int, int>{};
  for (final MapEntry(key: key, value: words) in verses.entries) {
    final [sura, number] = key.split(':').map(int.parse).toList();
    verseCounts[sura] = (verseCounts[sura] ?? 0) + 1;
    (int, int)? lastWordSlot;
    for (final word in words) {
      var slot = (word['p'] as int, word['l'] as int);
      if (word['c'] == 'end') {
        // The number always follows the verse's last word. The API puts a few of them (84:21)
        // on an earlier line than that word; they go with the word.
        if (lastWordSlot != null && _before(slot, lastWordSlot)) {
          stdout.writeln('$key: number moved to its last word\'s line');
          slot = lastWordSlot;
        }
        lineEnds.putIfAbsent(slot, () => {}).add(key);
        // In the print a number sometimes wraps to the start of the next line on its own.
        final segs = lineSegs.putIfAbsent(slot, () => []);
        if (segs.isEmpty || !segs.last.startsWith('$sura:$number:')) {
          segs.add('$sura:$number:-:');
        }
        continue;
      }
      lastWordSlot = slot;
      final segs = lineSegs.putIfAbsent(slot, () => []);
      // A rub el-hizb sign comes as part of the word after it, a space apart.
      final text = (word['t'] as String).trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty || RegExp(r'[|;:\n\r]').hasMatch(text)) {
        throw StateError('$key: unusable word "$text"');
      }
      if (segs.isNotEmpty && segs.last.startsWith('$sura:$number:')) {
        segs.last = '${segs.last} $text';
      } else {
        segs.add('$sura:$number:-:$text');
      }
    }
    if (key == '1:1') {
      basmala = [
        for (final w in words)
          if (w['c'] != 'end') w['t'] as String,
      ].join(' ');
    }
  }
  final slots = <(int, int), String>{};
  for (final MapEntry(key: slot, value: segs) in lineSegs.entries) {
    final ended = lineEnds[slot] ?? const {};
    slots[slot] =
        'a|${[for (final seg in segs) ended.contains(seg.split(':').take(2).join(':')) ? seg.replaceFirst(':-:', ':e:') : seg].join(';')}';
  }

  // The empty lines, in reading order, each run going to the sura that begins next.
  final order = [
    for (var page = 1; page <= _pageCount; page++)
      for (var line = 1; line <= (page <= 2 ? 8 : 15); line++) (page, line),
  ];
  for (var i = 0; i < order.length; i++) {
    if (slots.containsKey(order[i])) continue;
    final start = i;
    while (i < order.length && !slots.containsKey(order[i])) {
      i++;
    }
    if (i == order.length) throw StateError('empty lines at the very end');
    final next = slots[order[i]]!;
    final firstSeg = next.substring(2).split(';').first.split(':');
    final sura = int.parse(firstSeg[0]);
    if (firstSeg[1] != '1') {
      throw StateError('empty lines before ${firstSeg[0]}:${firstSeg[1]}');
    }
    final fill = ['s|$sura', if (sura != 1 && sura != 9) 'b|$basmala'];
    if (i - start != fill.length) {
      throw StateError(
        '${i - start} empty lines before sura $sura, expected ${fill.length}',
      );
    }
    for (var k = 0; k < fill.length; k++) {
      slots[order[start + k]] = fill[k];
    }
    i--;
  }
  if (slots.length != order.length) {
    throw StateError('lines outside the expected 15 per page');
  }

  final tanzil = <int, int>{};
  for (final line in File('assets/quran/quran-uthmani.txt').readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final sura = int.parse(line.split('|').first);
    tanzil[sura] = (tanzil[sura] ?? 0) + 1;
  }
  for (var sura = 1; sura <= 114; sura++) {
    if (tanzil[sura] != verseCounts[sura]) {
      throw StateError(
        'sura $sura: ${verseCounts[sura]} verses, Tanzil has ${tanzil[sura]}',
      );
    }
  }

  final out = StringBuffer()
    ..writeln(
      '# The 15-line Madinah mushaf (KFGQPC, 1421H print), line by line, in the',
    )
    ..writeln(
      "# King Fahd Complex's Uthmani Hafs text. From the Quran.com API v4, 2026-11-21.",
    )
    ..writeln(
      '# Written by tool/build_mushaf_lines.dart; do not edit by hand.',
    );
  for (final (int page, int line) in order) {
    out.writeln('$page|$line|${slots[(page, line)]}');
  }
  File(
    'assets/quran/mushaf-madinah-lines.txt',
  ).writeAsStringSync(out.toString());
  stdout.writeln('wrote ${order.length} lines');
}

Future<List<Map<String, dynamic>>> _fetch(HttpClient client, int page) async {
  final uri = Uri.https('api.quran.com', '/api/v4/verses/by_page/$page', {
    'mushaf': '1',
    'words': 'true',
    'per_page': '300',
    'word_fields': 'text_qpc_hafs,line_v2,v2_page,char_type_name',
    'fields': 'text_qpc_hafs',
  });
  for (var attempt = 0; ; attempt++) {
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != 200) {
        throw HttpException('${response.statusCode}');
      }
      final body =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      return [
        for (final v in (body['verses'] as List).cast<Map<String, dynamic>>())
          {
            'k': v['verse_key'],
            'w': [
              for (final w in (v['words'] as List).cast<Map<String, dynamic>>())
                {
                  't': w['text_qpc_hafs'],
                  'c': w['char_type_name'],
                  'l': w['line_v2'],
                  'p': w['v2_page'],
                },
            ],
          },
      ];
    } on Object {
      if (attempt == 4) rethrow;
      await Future<void>.delayed(Duration(seconds: 2 + attempt * 3));
    }
  }
}

bool _before((int, int) a, (int, int) b) =>
    a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 < b.$2);
