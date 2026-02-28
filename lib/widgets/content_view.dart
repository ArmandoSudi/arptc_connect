import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Material Design 3 Content View
///
/// A responsive container that provides:
/// - Adaptive padding based on breakpoints
/// - Maximum content width for readability
/// - Proper scroll behavior
class ContentView extends StatelessWidget {
  const ContentView({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.scrollable = false,
  });

  final Widget child;
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;

    final padding = isMobile
        ? const EdgeInsets.all(16)
        : isTablet
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
            : const EdgeInsets.symmetric(horizontal: 32, vertical: 24);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    // Apply max width constraint for larger screens
    if (!isMobile) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return content;
  }
}

/// Scrollable Content View
///
/// A content view with built-in scroll behavior
class ScrollableContentView extends StatelessWidget {
  const ScrollableContentView({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ContentView(
      maxWidth: maxWidth,
      scrollable: true,
      child: child,
    );
  }
}
