import 'package:flutter/material.dart';
import 'package:mynewapp/core/design_system/tokens.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';
import 'package:mynewapp/l10n/l10n.dart';

/// Draggable bottom sheet showing a titled block of text with a share action.
class HadithTextSheet extends StatelessWidget {
  const HadithTextSheet({
    super.key,
    required this.title,
    required this.text,
    required this.onShare,
  });

  final String title;
  final String text;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      fontWeight: FontWeight.bold,
                      alignment: AlignmentDirectional.centerStart,
                      color: AppColors.heading,
                      text: title,
                      fontSize: AppTextSize.heading,
                      isHeader: true,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.share,
                    icon: const Icon(Icons.share),
                    onPressed: onShare,
                  ),
                ],
              ),
              SelectionArea(
                child: CustomText(
                  fontWeight: FontWeight.normal,
                  alignment: AlignmentDirectional.centerStart,
                  text: text,
                  fontSize: AppTextSize.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
