import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/notifications/quiet_hours.dart';

int _m(int h, [int m = 0]) => h * 60 + m;

void main() {
  group('within one day (13:00 to 15:00)', () {
    final q = QuietHours(startMinute: _m(13), endMinute: _m(15));

    test('start is inside, end is outside', () {
      expect(q.contains(_m(13)), isTrue);
      expect(q.contains(_m(14, 59)), isTrue);
      expect(q.contains(_m(15)), isFalse);
      expect(q.contains(_m(12, 59)), isFalse);
    });

    test('does not cross midnight', () => expect(q.crossesMidnight, isFalse));
  });

  group('across midnight (22:00 to 07:00)', () {
    final q = QuietHours(startMinute: _m(22), endMinute: _m(7));

    test('late evening, midnight and early morning are quiet', () {
      expect(q.contains(_m(22)), isTrue);
      expect(q.contains(_m(23, 59)), isTrue);
      expect(q.contains(0), isTrue);
      expect(q.contains(_m(6, 59)), isTrue);
    });

    test('the day is not quiet, the end minute is not quiet', () {
      expect(q.contains(_m(7)), isFalse);
      expect(q.contains(_m(12)), isFalse);
      expect(q.contains(_m(21, 59)), isFalse);
    });

    test('crosses midnight', () => expect(q.crossesMidnight, isTrue));
  });

  test('equal start and end means no quiet time at all', () {
    final q = QuietHours(startMinute: _m(8), endMinute: _m(8));
    expect(q.isEmpty, isTrue);
    for (var m = 0; m < 1440; m += 30) {
      expect(q.contains(m), isFalse);
    }
  });
}
