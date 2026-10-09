import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/app_tile.dart';
import 'package:mynewapp/core/widgets/content_width.dart';
import 'package:mynewapp/core/widgets/state_views.dart';
import 'package:mynewapp/features/prayer_times/domain/city.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Pick a city by name (Arabic or English, ignoring diacritics and common spelling variants).
/// Pops with the chosen [City]. Needs no permission.
class CityPickerPage extends StatefulWidget {
  const CityPickerPage({super.key, required this.loadCities});

  final Future<CityCatalog> Function() loadCities;

  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  late final Future<CityCatalog> _catalog = widget.loadCities();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final language = context.apiLanguage;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cityPickerTitle)),
      body: ContentWidth(
        child: FutureBuilder<CityCatalog>(
          future: _catalog,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyView(
                message: l10n.errorUnexpected,
                icon: Icons.error_outline,
              );
            }
            final catalog = snapshot.data;
            if (catalog == null) return const LoadingView();
            final results = catalog.search(_query);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: TextField(
                    autofocus: false,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.citySearchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? EmptyView(
                          message: l10n.cityNoResults(_query.trim()),
                          icon: Icons.search_off,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          itemCount: results.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final city = results[index];
                            return AppTile(
                              title: city.name(language),
                              pressFeedback: true,
                              onTap: () => Navigator.of(context).pop(city),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
