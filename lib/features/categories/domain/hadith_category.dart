import 'package:equatable/equatable.dart';

/// One node of the HadeethEnc category tree. [parentId] is null for root categories.
class HadithCategory extends Equatable {
  const HadithCategory({
    required this.id,
    required this.title,
    required this.hadithCount,
    this.parentId,
  });

  final String id;
  final String title;
  final int hadithCount;
  final String? parentId;

  bool get isRoot => parentId == null;

  @override
  List<Object?> get props => [id, title, hadithCount, parentId];
}
