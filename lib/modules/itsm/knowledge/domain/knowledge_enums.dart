enum KnowledgeArticleState {
  draft('draft'),
  review('review'),
  published('published'),
  retired('retired'),
  archived('archived');

  const KnowledgeArticleState(this.value);

  final String value;

  static KnowledgeArticleState fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return switch (normalized) {
      'pending' || 'pending_review' || 'in_review' => review,
      'published' => published,
      'retired' => retired,
      'archived' => archived,
      _ => draft,
    };
  }
}

enum KnowledgeVisibility {
  employee('employee'),
  dsiOnly('dsi_only');

  const KnowledgeVisibility(this.value);

  final String value;

  static KnowledgeVisibility fromValue(Object? value) {
    final normalized = value
            ?.toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_') ??
        '';
    return normalized == 'dsi_only' || normalized == 'internal'
        ? dsiOnly
        : employee;
  }
}

enum KnowledgeTransitionAction {
  submitForReview,
  rejectToDraft,
  publish,
  retire,
  archive,
}

enum KnowledgePublishedView {
  search,
  featured,
  recent,
}

enum KnowledgeManagerQueue {
  all,
  authoredByMe,
  awaitingReview,
  drafts,
  published,
  retired,
  archived,
}
