import 'dart:math' as math;

import 'package:flutter/material.dart';

class SupportResponsiveGrid extends StatelessWidget {
  const SupportResponsiveGrid({
    required this.children,
    super.key,
    this.minimumItemWidth = 280,
    this.maximumColumns = 3,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minimumItemWidth;
  final int maximumColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final calculated =
            ((availableWidth + spacing) / (minimumItemWidth + spacing)).floor();
        final columns = math.max(1, math.min(maximumColumns, calculated));
        final itemWidth = (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
