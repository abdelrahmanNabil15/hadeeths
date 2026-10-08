import 'package:flutter/material.dart';
import 'package:mynewapp/core/widgets/custom_text.dart';

/// The rounded white card used for category entries (same look as the original grid).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title، $subtitle',
      excludeSemantics: true,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(100, 238, 231, 225),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: const Color.fromARGB(100, 245, 218, 176),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white60,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.center,
                  color: Colors.black,
                  text: title,
                  fontSize: 19,
                ),
                if (subtitle != null)
                  CustomText(
                    fontWeight: FontWeight.normal,
                    alignment: Alignment.center,
                    color: Colors.black54,
                    text: subtitle!,
                    fontSize: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
