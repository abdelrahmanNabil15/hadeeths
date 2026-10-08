import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../Model/hadith_details.dart';
import '../Shared/Network/hadeeth_api.dart';
import '../Shared/components/CustomText.dart';
import '../Shared/components/DraggableScrollableSheet.dart';
import '../Shared/components/state_views.dart';
import '../Shared/constant.dart';
import '../Shared/share_text.dart';
import 'categories/categories_cubit.dart' show LoadStatus;
import 'hadiths/hadith_detail_cubit.dart';

/// One hadith, loaded by id with its own cubit (independent of any list).
class HadithDetailsPage extends StatelessWidget {
  const HadithDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HadithDetailCubit(context.read<HadeethApi>(), id)..load(),
      child: Scaffold(
        appBar: AppBar(backgroundColor: appbarColor),
        body: BlocBuilder<HadithDetailCubit, HadithDetailState>(
          builder: (context, state) {
            switch (state.status) {
              case LoadStatus.initial:
              case LoadStatus.loading:
                return const LoadingView();
              case LoadStatus.failure:
                return ErrorView(
                  failure: state.failure!,
                  onRetry: context.read<HadithDetailCubit>().load,
                );
              case LoadStatus.success:
                return HadithDetailsBody(details: state.details!);
            }
          },
        ),
      ),
    );
  }
}

class HadithDetailsBody extends StatelessWidget {
  const HadithDetailsBody({super.key, required this.details});

  final HadithDetails details;

  @override
  Widget build(BuildContext context) {
    final d = details;
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'مشاركة الحديث',
                  icon: const Icon(Icons.share),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: hadithShareText(d)),
                  ),
                ),
                Customtext(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerRight,
                  color: mainColor,
                  text: 'الحديث:',
                  fontSize: 24,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectionArea(
                child: Customtext(
                  fontWeight: FontWeight.normal,
                  alignment: Alignment.centerRight,
                  color: Colors.black,
                  text: d.hadeeth,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (d.grade.isNotEmpty || d.attribution.isNotEmpty)
              Row(
                children: [
                  if (d.grade.isNotEmpty)
                    Expanded(
                      child: Customtext(
                        fontWeight: FontWeight.normal,
                        alignment: Alignment.centerLeft,
                        color: subColor,
                        text: '[${d.grade}]',
                        fontSize: 19,
                      ),
                    ),
                  if (d.attribution.isNotEmpty)
                    Expanded(
                      child: Customtext(
                        fontWeight: FontWeight.normal,
                        alignment: Alignment.centerLeft,
                        color: subColor,
                        text: '[${d.attribution}]',
                        fontSize: 19,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            if (d.explanation.isNotEmpty)
              _SectionRow(
                title: 'الشرح',
                onTap: () => _showTextSheet(context, 'الشرح:', d.explanation),
              ),
            if (d.hints.isNotEmpty)
              _SectionRow(
                title: 'الفوائد:',
                onTap: () => _showHintsSheet(context, d.hints),
              ),
            if (d.wordsMeanings.isNotEmpty) ...[
              Customtext(
                fontWeight: FontWeight.bold,
                alignment: Alignment.centerRight,
                color: mainColor,
                text: 'معاني الكلمات:',
                fontSize: 24,
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: d.wordsMeanings.length,
                separatorBuilder: (context, index) => Divider(color: subColor),
                itemBuilder: (context, index) {
                  final w = d.wordsMeanings[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Customtext(
                          fontWeight: FontWeight.normal,
                          alignment: Alignment.centerRight,
                          color: Colors.black,
                          text: w.meaning,
                          fontSize: 19,
                        ),
                      ),
                      Expanded(
                        child: Customtext(
                          fontWeight: FontWeight.bold,
                          alignment: Alignment.centerRight,
                          color: subColor,
                          text: w.word.isEmpty ? '' : '${w.word}:',
                          fontSize: 19,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (d.reference.isNotEmpty)
              _SectionRow(
                title: 'المصادر',
                onTap: () => _showTextSheet(context, 'المصادر:', d.reference),
              ),
            const SizedBox(height: 16),
            const Customtext(
              fontWeight: FontWeight.normal,
              alignment: Alignment.center,
              color: Colors.black54,
              text: hadeethEncCredit,
              fontSize: 14,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A tappable row that opens a secondary section.
class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.arrow_back_ios, color: mainColor),
              Customtext(
                fontWeight: FontWeight.bold,
                alignment: Alignment.centerRight,
                color: mainColor,
                text: title,
                fontSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showTextSheet(BuildContext context, String title, String text) {
  showModalBottomSheet<void>(
    isScrollControlled: true,
    context: context,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
    builder: (context) => customScrollableSheet(
      function: () =>
          SharePlus.instance.share(ShareParams(text: sectionShareText(text))),
      TextTitle: title,
      Text: text,
    ),
  );
}

void _showHintsSheet(BuildContext context, List<String> hints) {
  showModalBottomSheet<void>(
    isScrollControlled: true,
    enableDrag: true,
    context: context,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(12),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Customtext(
                fontWeight: FontWeight.bold,
                alignment: Alignment.centerRight,
                color: mainColor,
                text: 'الفوائد:',
                fontSize: 24,
              ),
            ),
            for (var i = 0; i < hints.length; i++) ...[
              Customtext(
                fontWeight: FontWeight.normal,
                alignment: Alignment.centerRight,
                color: Colors.black,
                text: '${i + 1}:  ${hints[i]}',
                fontSize: 19,
              ),
              if (i < hints.length - 1) const Divider(color: Colors.teal),
            ],
          ],
        ),
      ),
    ),
  );
}
