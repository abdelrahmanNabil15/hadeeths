import 'package:mynewapp/features/tasbeeh/domain/tasbeeh_counter.dart';

/// Keeps the counter between visits and restarts. Stored on the device only.
abstract interface class TasbeehRepository {
  /// The saved counter (zero, no target, if nothing was saved).
  Future<TasbeehCounter> load();

  Future<void> save(TasbeehCounter counter);
}
