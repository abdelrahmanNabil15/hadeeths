import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/quran/domain/quran_user_data.dart';
import 'package:mynewapp/features/quran/presentation/state/qiraat_cubit.dart';

import '../../support/quran_fakes.dart';

void main() {
  group('load', () {
    test('a verse with variations is held under its own key', () async {
      final cubit = QiraatCubit(FakeQuranContentRepository());
      expect(cubit.matrixFor(placeholderQiraatVerse), isNull);

      await cubit.load(placeholderQiraatVerse);
      expect(cubit.matrixFor(placeholderQiraatVerse), placeholderQiraatMatrix);
    });

    test(
      'a verse with none is held as an empty matrix, not left unset',
      () async {
        final cubit = QiraatCubit(FakeQuranContentRepository());
        const verse = VerseRef(3, 2);
        await cubit.load(verse);
        final matrix = cubit.matrixFor(verse);
        expect(matrix, isNotNull);
        expect(matrix!.hasVariations, isFalse);
      },
    );

    test('a different verse is fetched separately', () async {
      final repo = FakeQuranContentRepository();
      final cubit = QiraatCubit(repo);
      await cubit.load(placeholderQiraatVerse);
      await cubit.load(const VerseRef(1, 2));
      expect(repo.qiraatCalls, 2);
      expect(cubit.matrixFor(placeholderQiraatVerse)!.hasVariations, isTrue);
      expect(cubit.matrixFor(const VerseRef(1, 2))!.hasVariations, isFalse);
    });

    test('already held is not fetched again', () async {
      final repo = FakeQuranContentRepository();
      final cubit = QiraatCubit(repo);
      await cubit.load(placeholderQiraatVerse);
      await cubit.load(placeholderQiraatVerse);
      expect(repo.qiraatCalls, 1);
    });

    test('a failure is held, not silent', () async {
      final cubit = QiraatCubit(FakeQuranContentRepository(failQiraat: true));
      await cubit.load(placeholderQiraatVerse);
      expect(cubit.matrixFor(placeholderQiraatVerse), isNull);
      expect(
        cubit.failureFor(placeholderQiraatVerse)?.kind,
        FailureKind.server,
      );
    });

    test('a failed fetch is not retried on its own', () async {
      final repo = FakeQuranContentRepository(failQiraat: true);
      final cubit = QiraatCubit(repo);
      await cubit.load(placeholderQiraatVerse);
      await cubit.load(placeholderQiraatVerse);
      expect(repo.qiraatCalls, 1);
    });
  });

  group('retry', () {
    test('clears the failure so load tries again', () async {
      final repo = FakeQuranContentRepository(failQiraat: true);
      final cubit = QiraatCubit(repo);
      await cubit.load(placeholderQiraatVerse);
      expect(cubit.failureFor(placeholderQiraatVerse), isNotNull);

      repo.failQiraat = false;
      cubit.retry(placeholderQiraatVerse);
      expect(cubit.failureFor(placeholderQiraatVerse), isNull);

      await cubit.load(placeholderQiraatVerse);
      expect(cubit.matrixFor(placeholderQiraatVerse), placeholderQiraatMatrix);
      expect(repo.qiraatCalls, 2);
    });
  });
}
