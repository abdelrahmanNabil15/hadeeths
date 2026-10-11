import 'package:mynewapp/features/app_review/domain/review_state.dart';

/// Where the rating prompt's memory lives on the phone.
abstract interface class ReviewStore {
  /// The saved memory. Anything missing is empty; anything unreadable comes back with
  /// [ReviewState.lostHistory] set so the policy can be careful. Never throws.
  Future<ReviewState> load();

  Future<void> save(ReviewState state);

  /// Forgets everything ("Delete all my data").
  Future<void> clear();
}
