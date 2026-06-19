import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:flutter/material.dart';

class NewsStatusBadge extends StatelessWidget {
  const NewsStatusBadge({
    required this.status,
    super.key,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final resolved = NewsPostStatus.fromValue(status);
    final color = _colorFor(context, resolved);
    final l10n = S.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withOpacity(0.12),
      label: Text(
        _localizedStatusLabel(l10n, resolved),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Color _colorFor(BuildContext context, NewsPostStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case NewsPostStatus.draft:
        return scheme.onSurfaceVariant;
      case NewsPostStatus.pending:
        return Colors.orange;
      case NewsPostStatus.accepted:
        return Colors.teal;
      case NewsPostStatus.rejected:
        return scheme.error;
      case NewsPostStatus.published:
        return Colors.green;
      case NewsPostStatus.archived:
        return Colors.blueGrey;
    }
  }
}

String _localizedStatusLabel(S l10n, NewsPostStatus status) {
  switch (status) {
    case NewsPostStatus.draft:
      return l10n.draft;
    case NewsPostStatus.pending:
      return l10n.pending;
    case NewsPostStatus.accepted:
      return l10n.accepted;
    case NewsPostStatus.rejected:
      return l10n.rejected;
    case NewsPostStatus.published:
      return l10n.published;
    case NewsPostStatus.archived:
      return l10n.archived;
  }
}
