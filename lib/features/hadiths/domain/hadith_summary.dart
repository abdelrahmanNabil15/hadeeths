import 'package:equatable/equatable.dart';

/// A hadith as listed inside a category: only an id and a title are available.
class HadithSummary extends Equatable {
  const HadithSummary({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}
