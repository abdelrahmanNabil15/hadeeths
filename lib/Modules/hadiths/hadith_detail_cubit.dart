import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Model/hadith_details.dart';
import '../../Shared/errors/failure.dart';
import '../../Shared/Network/hadeeth_api.dart';
import '../categories/categories_cubit.dart' show LoadStatus;

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
  HadithDetailCubit(this._api, this.hadithId)
    : super(const HadithDetailState());

  final HadeethApi _api;
  final String hadithId;

  Future<void> load() async {
    emit(const HadithDetailState(status: LoadStatus.loading));
    try {
      final details = await _api.getHadithDetails(hadithId);
      if (isClosed) return;
      emit(HadithDetailState(status: LoadStatus.success, details: details));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(HadithDetailState(status: LoadStatus.failure, failure: f));
    }
  }
}
