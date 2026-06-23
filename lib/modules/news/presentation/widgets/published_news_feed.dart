import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_post_card.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header_simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class PublishedNewsFeed extends ConsumerWidget {
  const PublishedNewsFeed({
    this.title,
    this.description,
    this.detailPathBuilder,
    this.showBackButton = true,
    this.backRoute = '/service',
    super.key,
  });

  final String? title;
  final String? description;
  final String Function(NewsPost post)? detailPathBuilder;
  final bool showBackButton;
  final String backRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(publishedNewsPostsProvider);
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderSimple(
          title: title ?? l10n.companyNews,
          backButton: showBackButton,
          backRoute: backRoute,
        ),
        if (description?.trim().isNotEmpty ?? false) ...[
          const Gap(6),
          Padding(
            padding: EdgeInsets.only(left: showBackButton ? 48 : 0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
        const Gap(24),
        postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return SizedBox(
                height: 260,
                child: EmptyStateView(
                  icon: Icons.campaign_outlined,
                  title: l10n.noCompanyNewsYet,
                  description: l10n.publishedInformationWillAppearHere,
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final columnCount = _columnCountFor(constraints.maxWidth);
                final cardHeight = columnCount == 1 ? 400.0 : 420.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return NewsPostCard(
                      post: post,
                      showStatus: false,
                      layout: NewsPostCardLayout.grid,
                      onTap: () => context.go(
                        detailPathBuilder?.call(post) ??
                            '/home/news/${post.id}',
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => SizedBox(
            height: 220,
            child: LoadingStateView(message: l10n.loadingCompanyNews),
          ),
          error: (error, _) => SizedBox(
            height: 260,
            child: ErrorStateView(
              title: l10n.unableToLoadCompanyNews,
              description: error.toString(),
              onRetry: () => ref.invalidate(publishedNewsPostsProvider),
            ),
          ),
        ),
      ],
    );
  }

  int _columnCountFor(double width) {
    if (width >= 1180) return 3;
    if (width >= 700) return 2;
    return 1;
  }
}
