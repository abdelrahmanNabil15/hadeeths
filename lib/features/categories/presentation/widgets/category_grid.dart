import 'package:flutter/material.dart';
import 'package:mynewapp/features/categories/domain/hadith_category.dart';
import 'package:mynewapp/features/categories/presentation/widgets/category_card.dart';

/// Background image shared by the category screens.
class CategoryBackdrop extends StatelessWidget {
  const CategoryBackdrop({super.key, required this.child});

  final Widget child;

  @override
  // SizedBox.expand: a short list must still fill the screen with the backdrop.
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgruond.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    ),
  );
}

/// A two-column grid of [nodes] that grows with the user's text size.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.nodes, required this.onOpen});

  final List<HadithCategory> nodes;
  final void Function(HadithCategory node) onOpen;

  @override
  Widget build(BuildContext context) {
    final cellHeight = MediaQuery.textScalerOf(context).scale(120);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return CategoryCard(title: node.title, onTap: () => onOpen(node));
      },
    );
  }
}
