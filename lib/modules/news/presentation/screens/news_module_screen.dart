import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/screens/manager_news_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/news_feed_screen.dart';
import 'package:arptc_connect/modules/news/presentation/screens/reviewer_news_screen.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsModuleScreen extends ConsumerWidget {
  const NewsModuleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserNewsRoleProvider);

    return roleAsync.when(
      data: (role) {
        switch (role) {
          case NewsRole.manager:
            return const ManagerNewsScreen();
          case NewsRole.reviewer:
            return const ReviewerNewsScreen();
          case NewsRole.user:
            return const NewsFeedScreen();
          case NewsRole.none:
            return const ContentView(
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: 'News access unavailable',
                description: 'No News permission is assigned to this agent.',
              ),
            );
        }
      },
      loading: () => const ContentView(
        child: LoadingStateView(message: 'Loading news access...'),
      ),
      error: (error, _) => ContentView(
        child: ErrorStateView(
          title: 'Unable to load news access',
          description: error.toString(),
          onRetry: () => ref.invalidate(currentUserNewsRoleProvider),
        ),
      ),
    );
  }
}
