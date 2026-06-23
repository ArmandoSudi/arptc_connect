import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/published_news_feed.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:flutter/material.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 1440,
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PublishedNewsFeed(
              title: l10n.companyNews,
              description: l10n.homeNewsDescription,
              showBackButton: true,
              detailPathBuilder: _serviceNewsDetailPath,
            ),
          ],
        ),
      ),
    );
  }
}

String _serviceNewsDetailPath(post) => '/service/news/details/${post.id}';
