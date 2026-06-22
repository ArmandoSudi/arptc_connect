import 'dart:math' as math;

import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

class IncidentKpiCard extends StatelessWidget {
  const IncidentKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CorporateKpiCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      accentColor: color,
      onTap: onTap,
    );
  }
}

class IncidentResponsiveGrid extends StatelessWidget {
  const IncidentResponsiveGrid({
    required this.children,
    this.minItemWidth = 320,
    this.maxColumns = 3,
    this.spacing = 16,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final calculatedColumns = math.max(
          1,
          (availableWidth / minItemWidth).floor(),
        );
        final columns = math.min(maxColumns, calculatedColumns);
        final itemWidth = columns == 1
            ? availableWidth
            : (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class IncidentDashboardPanel extends StatelessWidget {
  const IncidentDashboardPanel({
    required this.title,
    required this.child,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CorporateSurfaceCard(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}
