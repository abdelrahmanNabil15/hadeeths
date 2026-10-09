import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/features/prayer_times/domain/geo_point.dart';
import 'package:mynewapp/features/prayer_times/domain/heading_calculator.dart';
import 'package:mynewapp/features/prayer_times/domain/prayer_services.dart';
import 'package:mynewapp/features/prayer_times/domain/qibla.dart';
import 'package:mynewapp/features/prayer_times/domain/world_magnetic_model.dart';

enum CompassStatus {
  /// Not running. The phone's sensors are not listened to.
  off,

  /// Sensors requested, no heading yet.
  starting,

  /// A heading is being shown.
  active,

  /// The device has no usable compass sensor, or reading it failed.
  unavailable,

  /// The magnetic correction data does not cover today's date; the compass is not offered
  /// rather than showing a heading that may be wrong.
  modelExpired,
}

class QiblaCompassState extends Equatable {
  const QiblaCompassState({
    this.status = CompassStatus.off,
    this.trueHeading,
    this.turn,
    this.aligned = false,
    this.interference = false,
    this.declination,
  });

  final CompassStatus status;

  /// Where the phone points, degrees clockwise from true north.
  final double? trueHeading;

  /// How far to turn to face the Qibla: -180 to 180, positive to the right.
  final double? turn;

  /// Facing the Qibla within the tolerance.
  final bool aligned;

  /// The magnetic field measured is far from what the Earth alone gives here: metal, a magnet or a
  /// case is disturbing the compass.
  final bool interference;

  /// The correction from magnetic to true north at this place and date, in degrees.
  final double? declination;

  @override
  List<Object?> get props => [
    status,
    trueHeading?.round(),
    turn?.round(),
    aligned,
    interference,
    declination?.toStringAsFixed(1),
  ];
}

/// The live compass for the Qibla screen. It runs only between [start] and [stop]; while it is off
/// nothing listens to the sensors. Nothing it reads is stored or sent.
class QiblaCompassCubit extends Cubit<QiblaCompassState> {
  QiblaCompassCubit({
    required this.services,
    required this.place,
    required this.qiblaBearing,
    this.alignedWithin = 5.0,
    this.startTimeout = const Duration(seconds: 4),
  }) : super(const QiblaCompassState());

  final PrayerServices services;
  final GeoPoint place;

  /// From true north, degrees.
  final double qiblaBearing;

  /// Facing the Qibla within this many degrees counts as aligned.
  final double alignedWithin;

  /// How long to wait for the first reading before saying the compass is unavailable.
  final Duration startTimeout;

  /// The measured field may differ this much (as a share) from the expected one before it is
  /// called interference.
  static const _fieldTolerance = 0.4;

  final _filter = CompassFilter();
  StreamSubscription<CompassSample>? _subscription;
  Timer? _timeout;
  double _declination = 0;
  double _expectedField = 0;

  Future<void> start() async {
    if (state.status == CompassStatus.starting ||
        state.status == CompassStatus.active) {
      return;
    }
    emit(const QiblaCompassState(status: CompassStatus.starting));
    final WorldMagneticModel model;
    try {
      model = await services.loadMagneticModel();
    } on Object {
      if (!isClosed) {
        emit(const QiblaCompassState(status: CompassStatus.unavailable));
      }
      return;
    }
    if (isClosed || state.status != CompassStatus.starting) return;
    final year = WorldMagneticModel.decimalYearOf(services.clock.now());
    if (!model.isValidAt(year)) {
      emit(const QiblaCompassState(status: CompassStatus.modelExpired));
      return;
    }
    final field = model.at(
      latitude: place.latitude,
      longitude: place.longitude,
      decimalYear: year,
    );
    _declination = field.declination;
    _expectedField = field.total / 1000; // nanotesla to microtesla
    _filter.reset();
    _timeout = Timer(startTimeout, () {
      if (state.status == CompassStatus.starting) _fail();
    });
    _subscription = services.compass.samples().listen(
      _onSample,
      onError: (Object _) => _fail(),
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    _timeout?.cancel();
    final subscription = _subscription;
    _subscription = null;
    // The screen goes back to "off" at once; releasing the sensors follows.
    if (!isClosed) emit(const QiblaCompassState());
    await subscription?.cancel();
  }

  void _fail() {
    _timeout?.cancel();
    _subscription?.cancel();
    _subscription = null;
    if (!isClosed) {
      emit(const QiblaCompassState(status: CompassStatus.unavailable));
    }
  }

  void _onSample(CompassSample sample) {
    final smooth = _filter.add(sample);
    final magnetic = HeadingCalculator.magneticHeading(smooth);
    if (magnetic == null) return;
    _timeout?.cancel();
    final heading = HeadingCalculator.wrap360(magnetic + _declination);
    final turn = Qibla.relativeTurn(qiblaBearing, heading);
    final ratio = smooth.magneticField.length / _expectedField;
    final interference =
        ratio < 1 - _fieldTolerance || ratio > 1 + _fieldTolerance;
    final next = QiblaCompassState(
      status: CompassStatus.active,
      trueHeading: heading,
      turn: turn,
      // Never claim "facing the Qibla" from a reading that is being disturbed.
      aligned: !interference && turn.abs() <= alignedWithin,
      interference: interference,
      declination: _declination,
    );
    // Whole degrees are enough to see; avoid redrawing for tiny changes.
    if (next != state) emit(next);
  }

  @override
  Future<void> close() async {
    _timeout?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
