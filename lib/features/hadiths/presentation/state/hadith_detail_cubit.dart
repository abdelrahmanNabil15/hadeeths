import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynewapp/core/errors/failure.dart';
import 'package:mynewapp/core/result/result.dart';
import 'package:mynewapp/core/state/load_status.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

class HadithDetailState extends Equatable {
  const HadithDetailState({
    this.status = LoadStatus.initial,
    this.details,
    this.failure,
  });

  final LoadStatus status;
  final HadithDetails? details;
  final Failure? failure;

  @override
  List<Object?> get props => [status, details, failure];
}

/// Loads exactly the hadith it was created for, independent of any list state.
class HadithDetailCubit extends Cubit<HadithDetailState> {
  HadithDetailCubit(this._repository, this.hadithId)
    : super(const HadithDetailState());

  final HadithsRepository _repository;
  final String hadithId;

  Future<void> load() async {
    emit(const HadithDetailState(status: LoadStatus.loading));
    final result = await _repository.getHadithDetails(hadithId);
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(HadithDetailState(status: LoadStatus.success, details: value));
      case Err(:final failure):
        emit(HadithDetailState(status: LoadStatus.failure, failure: failure));
    }
  }
}
