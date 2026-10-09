import 'dart:async';

import 'package:mynewapp/features/prayer_times/domain/compass_source.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Reads the accelerometer and the magnetometer with `sensors_plus` (BSD-3, Flutter Community).
/// A sample is produced each time the magnetometer reports, paired with the latest accelerometer
/// reading. About 20 readings a second; nothing is stored or sent.
class SensorsPlusCompassSource implements CompassSource {
  const SensorsPlusCompassSource({
    this.interval = const Duration(milliseconds: 50),
  });

  final Duration interval;

  @override
  Stream<CompassSample> samples() {
    late StreamController<CompassSample> controller;
    StreamSubscription<AccelerometerEvent>? accelerometer;
    StreamSubscription<MagnetometerEvent>? magnetometer;
    Vector3? lastAcceleration;

    void fail(Object error, StackTrace stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }

    controller = StreamController<CompassSample>(
      onListen: () {
        accelerometer = accelerometerEventStream(samplingPeriod: interval)
            .listen(
              (e) => lastAcceleration = Vector3(e.x, e.y, e.z),
              onError: fail,
            );
        magnetometer = magnetometerEventStream(samplingPeriod: interval).listen(
          (e) {
            final acceleration = lastAcceleration;
            if (acceleration == null) return;
            controller.add(
              CompassSample(
                acceleration: acceleration,
                magneticField: Vector3(e.x, e.y, e.z),
              ),
            );
          },
          onError: fail,
        );
      },
      onCancel: () async {
        await accelerometer?.cancel();
        await magnetometer?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }
}
