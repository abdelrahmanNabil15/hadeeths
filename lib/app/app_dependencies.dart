import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/categories/data/categories_remote_data_source.dart';
import 'package:mynewapp/features/categories/data/categories_repository_impl.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_remote_data_source.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_repository_impl.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';
import 'package:mynewapp/features/search/data/search_remote_data_source.dart';
import 'package:mynewapp/features/search/data/search_repository_impl.dart';
import 'package:mynewapp/features/search/domain/search_repository.dart';
import 'package:mynewapp/features/settings/data/settings_repository_impl.dart';
import 'package:mynewapp/features/settings/domain/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's repositories, built once at startup and handed to the widget tree through
/// `RepositoryProvider`. Tests construct this with fakes instead of calling [live].
class AppDependencies {
  const AppDependencies({
    required this.categories,
    required this.hadiths,
    required this.search,
    required this.settings,
  });

  /// Production wiring: the content repositories share one HTTP client.
  factory AppDependencies.live({required SharedPreferences preferences}) {
    final client = HadeethClient();
    return AppDependencies(
      categories: CategoriesRepositoryImpl(
        HttpCategoriesRemoteDataSource(client),
      ),
      hadiths: HadithsRepositoryImpl(HttpHadithsRemoteDataSource(client)),
      search: SearchRepositoryImpl(HttpSearchRemoteDataSource(client)),
      settings: SettingsRepositoryImpl(preferences),
    );
  }

  final CategoriesRepository categories;
  final HadithsRepository hadiths;
  final SearchRepository search;
  final SettingsRepository settings;
}
