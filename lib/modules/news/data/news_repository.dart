import 'package:arptc_connect/modules/news/data/news_actor.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';

abstract class NewsRepository {
  Stream<List<NewsPost>> watchPublishedPosts();

  Stream<List<NewsPost>> watchManagerPosts(String authorId);

  Stream<List<NewsPost>> watchPendingReviewPosts();

  Stream<NewsPost?> watchPostById(String postId);

  Future<String> createDraftPost(NewsPost post, NewsActor actor);

  Future<void> updateDraftPost(NewsPost post, NewsActor actor);

  Future<void> submitForReview(String postId, NewsActor actor);

  Future<void> acceptPost(String postId, NewsActor actor);

  Future<void> rejectPost({
    required String postId,
    required String comment,
    required NewsActor actor,
  });

  Future<void> publishPost(String postId, NewsActor actor);

  Future<void> archivePost(String postId, NewsActor actor);
}
