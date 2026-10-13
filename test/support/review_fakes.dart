import 'package:mynewapp/core/platform/app_version_source.dart';
import 'package:mynewapp/core/platform/review_gateway.dart';
import 'package:mynewapp/features/app_review/domain/review_state.dart';
import 'package:mynewapp/features/app_review/domain/review_store.dart';

/// The rating memory in memory. [failSave] makes saving throw; [loaded] is what the next
/// [load] answers.
class InMemoryReviewStore implements ReviewStore {
  InMemoryReviewStore([this.loaded = ReviewState.fresh]);

  ReviewState loaded;
  ReviewState? saved;
  bool failSave = false;
  int saves = 0;
  int clears = 0;

  @override
  Future<ReviewState> load() async => saved ?? loaded;

  @override
  Future<void> save(ReviewState state) async {
    if (failSave) throw StateError('disk full');
    saves++;
    saved = state;
  }

  @override
  Future<void> clear() async {
    clears++;
    saved = null;
    loaded = ReviewState.fresh;
  }
}

/// The platform's rating sheet and store page, counting what was asked of them.
class FakeReviewGateway implements ReviewGateway {
  bool available = true;
  bool canOpen = true;
  int availabilityChecks = 0;
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<void> requestReview() async => requests++;

  @override
  bool get canOpenStoreListing => canOpen;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

class FakeAppVersion implements AppVersionSource {
  FakeAppVersion([this.value = '1.1.0+2']);

  String? value;

  @override
  Future<String?> version() async => value;
}
