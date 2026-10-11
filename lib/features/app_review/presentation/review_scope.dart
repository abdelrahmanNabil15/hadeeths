import 'package:flutter/widgets.dart';
import 'package:mynewapp/features/app_review/domain/review_actions.dart';

/// Gives screens the rating actions, or nothing when the feature is off (and in tests that do not
/// use it). Screens ask with [maybeOf] and do nothing when the answer is null, so none of them
/// needs to know whether rating exists.
class ReviewScope extends InheritedWidget {
  const ReviewScope({super.key, required this.actions, required super.child});

  final ReviewActions? actions;

  /// The actions in effect, or null.
  static ReviewActions? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ReviewScope>()?.actions;

  @override
  bool updateShouldNotify(ReviewScope oldWidget) =>
      oldWidget.actions != actions;
}
