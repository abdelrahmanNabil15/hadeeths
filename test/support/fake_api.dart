import 'dart:async';

import 'package:mynewapp/Model/category_node.dart';
import 'package:mynewapp/Model/hadith_details.dart';
import 'package:mynewapp/Model/hadith_page.dart';
import 'package:mynewapp/Shared/Network/hadeeth_api.dart';
import 'package:mynewapp/Shared/errors/failure.dart';

import 'fixtures.dart';

/// Programmable [HadeethApi] that records how often it was called.
class FakeHadeethApi implements HadeethApi {
  FakeHadeethApi({
    List<CategoryNode>? categories,
    this.pages = const {},
    HadithDetails? details,
  }) : categories = categories ?? sampleCategories(),
       details = details ?? sampleDetails();

  List<CategoryNode> categories;

  /// Keyed by `"<categoryId>:<page>"`.
  Map<String, HadithPage> pages;
  HadithDetails details;

  /// While set, the next call of that kind throws it (once), then clears it.
  Failure? categoriesFailure;
  Failure? pageFailure;
  Failure? detailsFailure;

  /// When set, calls wait for it before answering (to test slow responses).
  Completer<void>? gate;

  int categoriesCalls = 0;
  final pageRequests = <String>[];
  final detailsRequests = <String>[];

  @override
  Future<List<CategoryNode>> getCategories({String language = 'ar'}) async {
    categoriesCalls++;
    await gate?.future;
    final failure = categoriesFailure;
    if (failure != null) {
      categoriesFailure = null;
      throw failure;
    }
    return categories;
  }

  @override
  Future<HadithPage> getHadithPage({
    required String categoryId,
    int page = 1,
    int perPage = HadeethApi.defaultPageSize,
    String language = 'ar',
  }) async {
    pageRequests.add('$categoryId:$page');
    await gate?.future;
    final failure = pageFailure;
    if (failure != null) {
      pageFailure = null;
      throw failure;
    }
    final result = pages['$categoryId:$page'];
    if (result == null) {
      throw const Failure(FailureKind.server, statusCode: 500);
    }
    return result;
  }

  @override
  Future<HadithDetails> getHadithDetails(
    String id, {
    String language = 'ar',
  }) async {
    detailsRequests.add(id);
    await gate?.future;
    final failure = detailsFailure;
    if (failure != null) {
      detailsFailure = null;
      throw failure;
    }
    return details;
  }
}

const noConnection = Failure(FailureKind.noConnection);
