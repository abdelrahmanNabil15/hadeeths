// JSON shaped like real HadeethEnc responses (captured from the live API, shortened).
// Ids and counts are strings; `last_page` and `total_items` are numbers; `current_page`
// and `per_page` are strings.

import 'package:mynewapp/features/categories/data/category_dto.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/hadiths/data/hadith_dtos.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_details.dart';
import 'package:mynewapp/features/hadiths/domain/hadith_page.dart';

/// Two roots, two children of root 1, and one grandchild. Root 2 is a leaf.
const categoriesJson = [
  {'id': '1', 'title': 'جذر أول', 'hadeeths_count': '197', 'parent_id': null},
  {'id': '2', 'title': 'جذر ثان', 'hadeeths_count': '16', 'parent_id': null},
  {'id': '8', 'title': 'فرع ثمانية', 'hadeeths_count': '76', 'parent_id': '1'},
  {'id': '9', 'title': 'فرع تسعة', 'hadeeths_count': '19', 'parent_id': '1'},
  {'id': '20', 'title': 'حفيد', 'hadeeths_count': '5', 'parent_id': '8'},
];

Map<String, dynamic> hadithPageJson({
  required List<String> ids,
  int page = 1,
  int lastPage = 1,
  int totalItems = -1,
}) => {
  'data': [
    for (final id in ids)
      {
        'id': id,
        'title': 'حديث $id',
        'translations': ['ar', 'en'],
      },
  ],
  'meta': {
    'current_page': '$page',
    'last_page': lastPage,
    'total_items': totalItems < 0 ? ids.length : totalItems,
    'per_page': '20',
  },
};

const arabicDetailsJson = {
  'id': '2962',
  'title': 'عنوان الحديث',
  'hadeeth': 'عَنْ عَبْدِ اللهِ بنِ مَسْعُودٍ رضي الله عنه',
  'attribution': 'متفق عليه',
  'grade': 'صحيح',
  'explanation': 'شرح الحديث',
  'hints': ['فائدة أولى', 'فائدة ثانية'],
  'categories': ['1', '8'],
  'translations': ['ar', 'en'],
  'hadeeth_intro': '',
  'words_meanings': [
    {'word': 'كلمة', 'meaning': 'معناها'},
  ],
  'reference': 'صحيح البخاري',
};

/// Non-Arabic responses have no `reference` and no `words_meanings`, and carry `*_ar` copies.
const englishDetailsJson = {
  'id': '2962',
  'title': 'The first case judged',
  'hadeeth': 'Narrated Abdullah ibn Masud',
  'attribution': 'Agreed upon',
  'grade': 'Sahih',
  'explanation': 'An explanation',
  'hints': ['A benefit'],
  'categories': ['1'],
  'translations': ['ar', 'en'],
  'hadeeth_intro': '',
  'title_ar': 'عنوان',
  'hadeeth_ar': 'نص',
  'grade_ar': 'صحيح',
  'words_meanings_ar': [],
};

List<HadithCategory> sampleCategories() => [
  for (final json in categoriesJson) CategoryDto.fromJson(json).toEntity(),
];

HadithPage samplePage({
  required List<String> ids,
  int page = 1,
  int lastPage = 1,
  int totalItems = -1,
}) => HadithPageDto.fromJson(
  hadithPageJson(
    ids: ids,
    page: page,
    lastPage: lastPage,
    totalItems: totalItems,
  ),
).toEntity();

HadithDetails sampleDetails([Map<String, dynamic> json = arabicDetailsJson]) =>
    HadithDetailsDto.fromJson(json).toEntity();
