import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/features/daily_hadith/domain/daily_hadith_service.dart';

enum DailyHadithStatus { loading, ready, none, failure }

class DailyHadithState extends Equatable {
  const DailyHadithState({
    this.status = DailyHadithStatus.loading,
    this.hadith,
    this.failure,
  });

  final DailyHadithStatus status;
  final DailyHadith? hadith;
  final Failure? failure;

  @override
  List<Object?> get props => [status, hadith, failure];
}

/// Loads today's hadith for the home card.
class DailyHadithCubit extends Cubit<DailyHadithState> {
  DailyHadithCubit(this._service, {required this.language})
    : super(const DailyHadithState());

  final DailyHadithService _service;
  final String language;

  Future<void> load() async {
    emit(const DailyHadithState());
    final result = await _service.today(language: language);
    if (isClosed) return;
    emit(switch (result) {
      Success(value: final hadith?) => DailyHadithState(
        status: DailyHadithStatus.ready,
        hadith: hadith,
      ),
      Success() => const DailyHadithState(status: DailyHadithStatus.none),
      Err(:final failure) => DailyHadithState(
        status: DailyHadithStatus.failure,
        failure: failure,
      ),
    });
  }
}
