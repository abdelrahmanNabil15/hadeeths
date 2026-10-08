import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/features/search/domain/hadith_search_result.dart';

String _plain(List<TextSegment> segments) => segments.map((s) => s.text).join();

void main() {
  group('parseHighlights', () {
    test('plain text is one unhighlighted run', () {
      expect(parseHighlights('no matches here'), const [
        TextSegment('no matches here'),
      ]);
    });

    test('marks become highlighted runs and the tags disappear', () {
      expect(parseHighlights('a <mark>b</mark> c <mark>d</mark>'), const [
        TextSegment('a '),
        TextSegment('b', highlighted: true),
        TextSegment(' c '),
        TextSegment('d', highlighted: true),
      ]);
    });

    test('the runs joined are the source text without the tags', () {
      const source =
          'إنما الأعمال <mark>بِالنِّيَّةِ</mark>، وإنما لكل امرئ ما نوى';
      expect(
        _plain(parseHighlights(source)),
        source.replaceAll('<mark>', '').replaceAll('</mark>', ''),
      );
    });

    test('a missing closing tag highlights to the end instead of failing', () {
      expect(parseHighlights('a <mark>b'), const [
        TextSegment('a '),
        TextSegment('b', highlighted: true),
      ]);
    });

    test('empty input is no runs', () {
      expect(parseHighlights(''), isEmpty);
    });
  });

  group('excerptAround', () {
    List<TextSegment> longText({required int before, required int after}) => [
      TextSegment('x' * before),
      const TextSegment('MATCH', highlighted: true),
      TextSegment('y' * after),
    ];

    test('a short text is returned whole, with no ellipses', () {
      final e = excerptAround(parseHighlights('a <mark>b</mark> c'));
      expect(_plain(e.segments), 'a b c');
      expect(e.leading, isFalse);
      expect(e.trailing, isFalse);
    });

    test('a match deep in a long text is windowed with both ellipses', () {
      final e = excerptAround(longText(before: 400, after: 400), radius: 50);
      expect(e.leading, isTrue);
      expect(e.trailing, isTrue);
      expect(_plain(e.segments), contains('MATCH'));
      expect(_plain(e.segments).length, lessThanOrEqualTo(100));
      expect(e.segments.where((s) => s.highlighted).single.text, 'MATCH');
    });

    test('a match near the start has no leading ellipsis', () {
      final e = excerptAround(longText(before: 10, after: 400), radius: 50);
      expect(e.leading, isFalse);
      expect(e.trailing, isTrue);
    });

    test('without any match the excerpt starts at the beginning', () {
      final e = excerptAround([TextSegment('z' * 500)], radius: 50);
      expect(e.leading, isFalse);
      expect(e.trailing, isTrue);
      expect(_plain(e.segments).length, 100);
    });

    test('the excerpt is always a contiguous piece of the original text', () {
      final segments = longText(before: 300, after: 300);
      final whole = _plain(segments);
      final e = excerptAround(segments, radius: 60);
      expect(whole, contains(_plain(e.segments)));
    });
  });
}
