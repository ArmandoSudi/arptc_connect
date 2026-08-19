import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/news/data/news_actor.dart';
import 'package:arptc_connect/modules/news/data/news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return FirestoreNewsRepository(ref.read(fireStoreProvider));
});

class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      firestore.collection('newsPosts');

  @override
  Stream<List<NewsPost>> watchPublishedPosts() {
    return _watchPosts(
      _posts.where('status', isEqualTo: NewsPostStatus.published.value),
      sort: _comparePublishedDescending,
    );
  }

  @override
  Stream<List<NewsPost>> watchManagerPosts(String authorId) {
    if (authorId.trim().isEmpty) {
      return Stream.value(const <NewsPost>[]);
    }
    return _watchPosts(
      _posts.where('authorId', isEqualTo: authorId),
      sort: _compareUpdatedDescending,
    );
  }

  @override
  Stream<List<NewsPost>> watchPendingReviewPosts() {
    return _watchPosts(
      _posts.where('status', isEqualTo: NewsPostStatus.pending.value),
      sort: _compareSubmittedAscending,
    );
  }

  @override
  Stream<NewsPost?> watchPostById(String postId) {
    return _posts.doc(postId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return NewsPost.fromFirestore(snapshot);
    });
  }

  @override
  Future<String> createDraftPost(NewsPost post, NewsActor actor) async {
    final doc = _posts.doc();
    final data = post
        .copyWith(
          id: doc.id,
          authorId: actor.userId,
          authorName: actor.name,
          authorEmail: actor.email,
          status: NewsPostStatus.draft.value,
          reviewComment: '',
          reviewedByUserId: '',
          reviewedByName: '',
          reviewedByEmail: '',
        )
        .toFirestore();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    return doc.id;
  }

  @override
  Future<void> updateDraftPost(NewsPost post, NewsActor actor) async {
    await _posts.doc(post.id).update({
      'title': post.title.trim(),
      'titleLower': post.title.trim().toLowerCase(),
      'content': post.content.trim(),
      'imageUrl': post.imageUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> submitForReview(String postId, NewsActor actor) async {
    final postRef = _posts.doc(postId);
    await postRef.update({
      'status': NewsPostStatus.pending.value,
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewComment': '',
      'reviewedByUserId': '',
      'reviewedByName': '',
      'reviewedByEmail': '',
      'reviewedAt': null,
      'acceptedAt': null,
      'rejectedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> acceptPost(String postId, NewsActor actor) async {
    final postRef = _posts.doc(postId);
    await postRef.update({
      'status': NewsPostStatus.accepted.value,
      'reviewComment': '',
      'reviewedByUserId': actor.userId,
      'reviewedByName': actor.name,
      'reviewedByEmail': actor.email,
      'reviewedAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
      'rejectedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectPost({
    required String postId,
    required String comment,
    required NewsActor actor,
  }) async {
    final postRef = _posts.doc(postId);
    await postRef.update({
      'status': NewsPostStatus.rejected.value,
      'reviewComment': comment.trim(),
      'reviewedByUserId': actor.userId,
      'reviewedByName': actor.name,
      'reviewedByEmail': actor.email,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectedAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> publishPost(String postId, NewsActor actor) async {
    final postRef = _posts.doc(postId);
    await postRef.update({
      'status': NewsPostStatus.published.value,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> archivePost(String postId, NewsActor actor) async {
    await _posts.doc(postId).update({
      'status': NewsPostStatus.archived.value,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<NewsPost>> _watchPosts(
    Query<Map<String, dynamic>> query, {
    required int Function(NewsPost left, NewsPost right) sort,
  }) {
    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs.map(NewsPost.fromFirestore).toList()
        ..sort(sort);
      return posts;
    });
  }
}

int _comparePublishedDescending(NewsPost left, NewsPost right) {
  return _compareDateDescending(
    left.publishedAt ?? left.updatedAt ?? left.createdAt,
    right.publishedAt ?? right.updatedAt ?? right.createdAt,
  );
}

int _compareUpdatedDescending(NewsPost left, NewsPost right) {
  return _compareDateDescending(
    left.updatedAt ?? left.createdAt,
    right.updatedAt ?? right.createdAt,
  );
}

int _compareSubmittedAscending(NewsPost left, NewsPost right) {
  return _compareDateAscending(
    left.submittedAt ?? left.updatedAt ?? left.createdAt,
    right.submittedAt ?? right.updatedAt ?? right.createdAt,
  );
}

int _compareDateDescending(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return right.compareTo(left);
}

int _compareDateAscending(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}
