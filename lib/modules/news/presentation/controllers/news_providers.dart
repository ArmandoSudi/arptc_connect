import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/news/data/news_actor.dart';
import 'package:arptc_connect/modules/news/data/firestore_news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/domain/news_user.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserNewsRoleProvider = Provider<AsyncValue<NewsRole>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData(_roleFromProfile);
});

final currentNewsUserProvider = Provider<AsyncValue<NewsUser>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData((profile) {
    final authUser = ref.read(firebaseAuthProvider).currentUser;
    final displayName = _displayNameFromProfile(profile);
    final profileId = _string(profile['id']);
    return NewsUser(
      id: profileId.isNotEmpty ? profileId : authUser?.uid ?? '',
      displayName: displayName.isNotEmpty ? displayName : 'Agent',
      email: _string(profile['email']),
      role: _roleFromProfile(profile),
    );
  });
});

final currentNewsActorProvider = Provider<AsyncValue<NewsActor>>((ref) {
  final userAsync = ref.watch(currentNewsUserProvider);
  return userAsync.whenData((user) {
    return NewsActor(
      userId: user.id,
      name: user.displayName,
      email: user.email,
      role: user.role,
    );
  });
});

final publishedNewsPostsProvider = StreamProvider<List<NewsPost>>((ref) {
  final sessionKey = ref.watch(currentAuthSessionKeyProvider);
  if (sessionKey == null) {
    return Stream.value(const <NewsPost>[]);
  }
  return ref.read(newsRepositoryProvider).watchPublishedPosts();
});

final managerNewsPostsProvider = StreamProvider<List<NewsPost>>((ref) {
  final sessionKey = ref.watch(currentAuthSessionKeyProvider);
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (sessionKey == null || authUser == null) {
    return Stream.value(const <NewsPost>[]);
  }

  final user = ref.watch(currentNewsUserProvider).valueOrNull;
  if (user == null ||
      user.id.isEmpty ||
      !_newsUserMatchesAuthUser(user, authUser.uid, authUser.email)) {
    return Stream.value(const <NewsPost>[]);
  }
  return ref.read(newsRepositoryProvider).watchManagerPosts(user.id);
});

final pendingReviewNewsPostsProvider = StreamProvider<List<NewsPost>>((ref) {
  final sessionKey = ref.watch(currentAuthSessionKeyProvider);
  if (sessionKey == null) {
    return Stream.value(const <NewsPost>[]);
  }
  return ref.read(newsRepositoryProvider).watchPendingReviewPosts();
});

final newsPostProvider = StreamProvider.family<NewsPost?, String>(
  (ref, postId) {
    final sessionKey = ref.watch(currentAuthSessionKeyProvider);
    if (sessionKey == null) {
      return Stream.value(null);
    }
    return ref.read(newsRepositoryProvider).watchPostById(postId);
  },
);

NewsRole _roleFromProfile(Map<String, dynamic> profile) {
  final rawPermissions = profile['modulePermissions'];
  final permissions = Modules.normalizePermissions(
    rawPermissions is Map<String, dynamic>
        ? rawPermissions
        : rawPermissions is Map
            ? Map<String, dynamic>.from(rawPermissions)
            : null,
    includeDefaultModules: false,
  );

  final roleValue = permissions['news'] ??
      permissions['communication'] ??
      permissions['communications'] ??
      permissions['feed'] ??
      ModuleAccessRole.none.value;

  return NewsRole.fromValue(roleValue);
}

String _displayNameFromProfile(Map<String, dynamic> profile) {
  final pieces = [
    _string(profile['firstName']),
    _string(profile['name']),
    _string(profile['postName']),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }
  return _string(profile['fullName']);
}

String _string(dynamic value) => value?.toString().trim() ?? '';

bool _newsUserMatchesAuthUser(
  NewsUser newsUser,
  String authUserId,
  String? authEmail,
) {
  if (newsUser.id == authUserId) {
    return true;
  }

  final normalizedAuthEmail = _string(authEmail).toLowerCase();
  return normalizedAuthEmail.isNotEmpty &&
      newsUser.email.toLowerCase() == normalizedAuthEmail;
}
