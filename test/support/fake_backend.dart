import 'dart:async';

import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

import 'fixtures.dart';

/// Programmable stand-in for both repositories. It records how often it was called.
class FakeBackend implements CategoriesRepository, HadithsRepository {
  FakeBackend({
    List<HadithCategory>? categories,
    this.pages = const {},
    HadithDetails? details,
  }) : categories = categories ?? sampleCategories(),
       details = details ?? sampleDetails();

  List<HadithCategory> categories;

  /// Keyed by `"<categoryId>:<page>"`.
  Map<String, HadithPage> pages;
  HadithDetails details;

  /// While set, the next call of that kind returns it (once), then clears it.
  Failure? categoriesFailure;
  Failure? pageFailure;
  Failure? detailsFailure;

  /// When set, calls wait for it before answering (to test slow responses).
  Completer<void>? gate;

  int categoriesCalls = 0;
  final pageRequests = <String>[];
  final detailsRequests = <String>[];

  @override
  Future<Result<List<HadithCategory>>> getCategories() async {
    categoriesCalls++;
    await gate?.future;
    final failure = categoriesFailure;
    if (failure != null) {
      categoriesFailure = null;
      return Err(failure);
    }
    return Success(categories);
  }

  @override
  Future<Result<HadithPage>> getHadithPage({
    required String categoryId,
    int page = 1,
    int perPage = HadithsRepository.defaultPageSize,
  }) async {
    pageRequests.add('$categoryId:$page');
    await gate?.future;
    final failure = pageFailure;
    if (failure != null) {
      pageFailure = null;
      return Err(failure);
    }
    final result = pages['$categoryId:$page'];
    if (result == null) {
      return const Err(Failure(FailureKind.server, statusCode: 500));
    }
    return Success(result);
  }

  @override
  Future<Result<HadithDetails>> getHadithDetails(String id) async {
    detailsRequests.add(id);
    await gate?.future;
    final failure = detailsFailure;
    if (failure != null) {
      detailsFailure = null;
      return Err(failure);
    }
    return Success(details);
  }
}

const noConnection = Failure(FailureKind.noConnection);
