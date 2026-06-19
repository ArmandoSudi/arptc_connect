import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_news_helpers.dart';
import 'news_enums.dart';

class NewsPost {
  const NewsPost({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.status,
    required this.reviewComment,
    required this.reviewedByUserId,
    required this.reviewedByName,
    required this.reviewedByEmail,
    required this.submittedAt,
    required this.reviewedAt,
    required this.acceptedAt,
    required this.rejectedAt,
    required this.publishedAt,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String status;
  final String reviewComment;
  final String reviewedByUserId;
  final String reviewedByName;
  final String reviewedByEmail;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? publishedAt;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NewsPost.empty() {
    return const NewsPost(
      id: '',
      title: '',
      content: '',
      imageUrl: '',
      authorId: '',
      authorName: '',
      authorEmail: '',
      status: 'DRAFT',
      reviewComment: '',
      reviewedByUserId: '',
      reviewedByName: '',
      reviewedByEmail: '',
      submittedAt: null,
      reviewedAt: null,
      acceptedAt: null,
      rejectedAt: null,
      publishedAt: null,
      archivedAt: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  factory NewsPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return NewsPost(
      id: snapshot.id,
      title: stringFromFirestore(data, 'title'),
      content: stringFromFirestore(data, 'content'),
      imageUrl: stringFromFirestore(data, 'imageUrl'),
      authorId: stringFromFirestore(data, 'authorId'),
      authorName: stringFromFirestore(data, 'authorName'),
      authorEmail: stringFromFirestore(data, 'authorEmail'),
      status: NewsPostStatus.fromValue(data['status']?.toString()).value,
      reviewComment: stringFromFirestore(data, 'reviewComment'),
      reviewedByUserId: stringFromFirestore(data, 'reviewedByUserId'),
      reviewedByName: stringFromFirestore(data, 'reviewedByName'),
      reviewedByEmail: stringFromFirestore(data, 'reviewedByEmail'),
      submittedAt: dateTimeFromFirestore(data['submittedAt']),
      reviewedAt: dateTimeFromFirestore(data['reviewedAt']),
      acceptedAt: dateTimeFromFirestore(data['acceptedAt']),
      rejectedAt: dateTimeFromFirestore(data['rejectedAt']),
      publishedAt: dateTimeFromFirestore(data['publishedAt']),
      archivedAt: dateTimeFromFirestore(data['archivedAt']),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.trim(),
      'titleLower': title.trim().toLowerCase(),
      'content': content.trim(),
      'imageUrl': imageUrl.trim(),
      'authorId': authorId.trim(),
      'authorName': authorName.trim(),
      'authorEmail': authorEmail.trim(),
      'status': NewsPostStatus.fromValue(status).value,
      'reviewComment': reviewComment.trim(),
      'reviewedByUserId': reviewedByUserId.trim(),
      'reviewedByName': reviewedByName.trim(),
      'reviewedByEmail': reviewedByEmail.trim(),
      'submittedAt': dateTimeToFirestore(submittedAt),
      'reviewedAt': dateTimeToFirestore(reviewedAt),
      'acceptedAt': dateTimeToFirestore(acceptedAt),
      'rejectedAt': dateTimeToFirestore(rejectedAt),
      'publishedAt': dateTimeToFirestore(publishedAt),
      'archivedAt': dateTimeToFirestore(archivedAt),
      'createdAt': dateTimeToFirestore(createdAt),
      'updatedAt': dateTimeToFirestore(updatedAt),
    };
  }

  NewsPost copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? status,
    String? reviewComment,
    String? reviewedByUserId,
    String? reviewedByName,
    String? reviewedByEmail,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? publishedAt,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      status: status ?? this.status,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedByEmail: reviewedByEmail ?? this.reviewedByEmail,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
