import 'package:flutter/material.dart';
import 'package:mynewapp/core/constants/app_colors.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'مشاركة',
                    icon: const Icon(Icons.share),
                    onPressed: onShare,
                  ),
                  CustomText(
                    fontWeight: FontWeight.bold,
                    alignment: Alignment.centerRight,
                    color: mainColor,
                    text: title,
                    fontSize: 24,
                  ),
                ],
              ),
              CustomText(
                fontWeight: FontWeight.normal,
                alignment: Alignment.centerRight,
                color: Colors.black,
                text: text,
                fontSize: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
