import 'package:mynewapp/core/json/json_helpers.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';

/// A category as the HadeethEnc API sends it (ids and counts arrive as strings).
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.title,
    required this.hadithCount,
    this.parentId,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    if (id.isEmpty) throw const FormatException('Category without id');
    final parent = json['parent_id'];
    return CategoryDto(
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

  HadithCategory toEntity() => HadithCategory(
    id: id,
    title: title,
    hadithCount: hadithCount,
    parentId: parentId,
  );
}
