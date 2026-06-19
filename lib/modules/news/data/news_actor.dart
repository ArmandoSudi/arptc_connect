import 'package:arptc_connect/modules/news/domain/news_enums.dart';

class NewsActor {
  const NewsActor({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String userId;
  final String name;
  final String email;
  final NewsRole role;

  bool get isEmpty => userId.trim().isEmpty && email.trim().isEmpty;
}
