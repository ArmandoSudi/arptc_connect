import 'news_enums.dart';

class NewsUser {
  const NewsUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String id;
  final String displayName;
  final String email;
  final NewsRole role;
}
