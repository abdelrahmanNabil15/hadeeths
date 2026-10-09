import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';

/// The phone's motion sensors. Listening starts them; cancelling the subscription stops them, so
/// nothing runs while the compass is off. An error on the stream means a sensor is missing or
/// cannot be read.
abstract interface class CompassSource {
  Stream<CompassSample> samples();
}
