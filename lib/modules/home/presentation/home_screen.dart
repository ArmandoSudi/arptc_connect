import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/published_news_feed.dart';
import 'package:arptc_connect/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxContentWidth: 1440,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Gap(32),
            PublishedNewsFeed(
              title: l10n.homeNewsTitle,
              description: l10n.homeNewsDescription,
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
