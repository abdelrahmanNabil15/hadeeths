import 'package:equatable/equatable.dart';

import 'json_helpers.dart';

/// One node of the HadeethEnc category tree. [parentId] is null for root categories.
class CategoryNode extends Equatable {
  const CategoryNode({
    required this.id,
    required this.title,
    required this.hadithCount,
    this.parentId,
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Category without id');
    final parent = json['parent_id'];
    return CategoryNode(
      id: id,
      title: asString(json['title']),
      hadithCount: asInt(json['hadeeths_count'], 0),
      parentId: parent == null ? null : asString(parent),
    );
  }

  final String id;
  final String title;
  final int hadithCount;
  final String? parentId;

  bool get isRoot => parentId == null;

  @override
  List<Object?> get props => [id, title, hadithCount, parentId];
}
