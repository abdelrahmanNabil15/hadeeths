import 'package:mynewapp/core/cache/cached_fetcher.dart';
import 'package:mynewapp/core/cache/response_cache.dart';
import 'package:mynewapp/core/database/user_database.dart';
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
    required this.cache,
    this.userData,
  });

  /// Production wiring: the content repositories share one HTTP client and one saved-copy
  /// cache. Search is never cached (it needs the server's current index).
  factory AppDependencies.live({
    required SharedPreferences preferences,
    required SwitchableResponseCache cache,
    HadeethClient? client,
    UserDatabase? userData,
  }) {
    final http = client ?? HadeethClient();
    final fetcher = CachedFetcher(cache);
    return AppDependencies(
      categories: CategoriesRepositoryImpl(
        HttpCategoriesRemoteDataSource(http, fetcher),
      ),
      hadiths: HadithsRepositoryImpl(
        HttpHadithsRemoteDataSource(http, fetcher),
      ),
      search: SearchRepositoryImpl(HttpSearchRemoteDataSource(http)),
      settings: SettingsRepositoryImpl(preferences),
      cache: cache,
      userData: userData,
    );
  }

  final CategoriesRepository categories;
  final HadithsRepository hadiths;
  final SearchRepository search;
  final SettingsRepository settings;

  /// Saved copies of opened content; switched on and off by the user's setting.
  final SwitchableResponseCache cache;

  /// The user's own data (favourites, tracker, ...). `null` when it could not be opened;
  /// features that need it must then show an unavailable state rather than crash.
  final UserDatabase? userData;
}
