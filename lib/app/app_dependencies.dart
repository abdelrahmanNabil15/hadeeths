import 'package:mynewapp/core/network/hadeeth_client.dart';
import 'package:mynewapp/features/categories/data/categories_remote_data_source.dart';
import 'package:mynewapp/features/categories/data/categories_repository_impl.dart';
import 'package:mynewapp/features/categories/domain/categories_repository.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_remote_data_source.dart';
import 'package:mynewapp/features/hadiths/data/hadiths_repository_impl.dart';
import 'package:mynewapp/features/hadiths/domain/hadiths_repository.dart';

/// The app's repositories, built once at startup and handed to the widget tree through
/// `RepositoryProvider`. Tests construct this with fakes instead of calling [live].
class AppDependencies {
  const AppDependencies({required this.categories, required this.hadiths});

  /// Production wiring: both repositories share one HTTP client.
  factory AppDependencies.live() {
    final client = HadeethClient();
    return AppDependencies(
      categories: CategoriesRepositoryImpl(
        HttpCategoriesRemoteDataSource(client),
      ),
      hadiths: HadithsRepositoryImpl(HttpHadithsRemoteDataSource(client)),
    );
  }

  final CategoriesRepository categories;
  final HadithsRepository hadiths;
}
