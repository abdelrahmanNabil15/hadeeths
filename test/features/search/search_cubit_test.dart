import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';
import 'package:mynewapp/features/search/presentation/state/search_cubit.dart';

import '../../support/fake_backend.dart';
import '../../support/fixtures.dart';

const _debounce = Duration(milliseconds: 5);
const _settle = Duration(milliseconds: 60);

SearchCubit _cubit(FakeBackend api, {String language = 'ar'}) =>
    SearchCubit(api, language: language, debounce: _debounce);

Future<void> _wait() => Future<void>.delayed(_settle);

void main() {
  test('starts idle', () {
    expect(_cubit(FakeBackend()).state.status, SearchStatus.idle);
  });

  test(
    'fewer characters than the server accepts never reach the server',
    () async {
      final api = FakeBackend();
      final cubit = _cubit(api);
      cubit.onQueryChanged('ab');
      await _wait();
      expect(cubit.state.status, SearchStatus.tooShort);
      expect(api.searchPhrases, isEmpty);
      await cubit.close();
    },
  );

  test('the minimum length counts the trimmed phrase', () async {
    final api = FakeBackend();
    final cubit = _cubit(api);
    cubit.onQueryChanged('  ab  ');
    await _wait();
    expect(cubit.state.status, SearchStatus.tooShort);
    expect(api.searchPhrases, isEmpty);
    await cubit.close();
  });

  test('a phrase of the minimum length is searched after a pause', () async {
    final api = FakeBackend();
    final cubit = _cubit(api, language: 'en');
    cubit.onQueryChanged('abc');
    expect(cubit.state.status, SearchStatus.loading);
    await _wait();
    expect(cubit.state.status, SearchStatus.success);
    expect(cubit.state.results, hasLength(2));
    expect(cubit.state.query, 'abc');
    expect(api.searchPhrases, ['abc']);
    expect(api.languages, ['en']);
    await cubit.close();
  });

  test('typing quickly searches only the last phrase', () async {
    final api = FakeBackend();
    final cubit = _cubit(api);
    cubit.onQueryChanged('abc');
    cubit.onQueryChanged('abcd');
    cubit.onQueryChanged('abcde');
    await _wait();
    expect(api.searchPhrases, ['abcde']);
    await cubit.close();
  });

  test('an answer that arrives after the phrase changed is ignored', () async {
    final api = FakeBackend()..gate = Completer<void>();
    final cubit = _cubit(api);
    cubit.onQueryChanged('abc');
    await _wait(); // request for "abc" is now waiting on the gate
    api.searchResults = sampleSearchResults(count: 1);
    cubit.onQueryChanged('ab'); // user deleted a letter: too short now
    api.gate!.complete();
    await _wait();
    expect(cubit.state.status, SearchStatus.tooShort);
    expect(cubit.state.results, isEmpty);
    await cubit.close();
  });

  test(
    'clearing the field returns to idle and cancels a pending search',
    () async {
      final api = FakeBackend();
      final cubit = _cubit(api);
      cubit.onQueryChanged('abc');
      cubit.onQueryChanged('');
      await _wait();
      expect(cubit.state.status, SearchStatus.idle);
      expect(api.searchPhrases, isEmpty);
      await cubit.close();
    },
  );

  test('no matches is a success with an empty list', () async {
    final api = FakeBackend(searchResults: const []);
    final cubit = _cubit(api);
    cubit.onQueryChanged('zzzz');
    await _wait();
    expect(cubit.state.status, SearchStatus.success);
    expect(cubit.state.results, isEmpty);
    await cubit.close();
  });

  test('a failure ends in a failure state and retry recovers', () async {
    final api = FakeBackend()..searchFailure = noConnection;
    final cubit = _cubit(api);
    cubit.onQueryChanged('abc');
    await _wait();
    expect(cubit.state.status, SearchStatus.failure);
    expect(cubit.state.failure!.kind, FailureKind.noConnection);

    cubit.retry();
    await _wait();
    expect(cubit.state.status, SearchStatus.success);
    expect(api.searchPhrases, ['abc', 'abc']);
    await cubit.close();
  });

  test('a full page of results is flagged as possibly truncated', () async {
    final api = FakeBackend(
      searchResults: sampleSearchResults(count: SearchRepository.maxResults),
    );
    final cubit = _cubit(api);
    cubit.onQueryChanged('abc');
    await _wait();
    expect(cubit.state.mayBeTruncated, isTrue);
    await cubit.close();
  });

  test('fewer results than the limit are not flagged', () async {
    final cubit = _cubit(FakeBackend());
    cubit.onQueryChanged('abc');
    await _wait();
    expect(cubit.state.mayBeTruncated, isFalse);
    await cubit.close();
  });
}
