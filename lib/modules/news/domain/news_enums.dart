enum NewsRole {
  none('NONE', 'No access'),
  user('USER', 'User'),
  manager('MANAGER', 'Manager'),
  reviewer('REVIEWER', 'Reviewer');

  const NewsRole(this.value, this.label);

  final String value;
  final String label;

  static NewsRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final role in NewsRole.values) {
      if (role.value == normalized) {
        return role;
      }
    }
    return NewsRole.none;
  }
}

enum NewsPostStatus {
  draft('DRAFT', 'Draft'),
  pending('PENDING', 'Pending review'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected'),
  published('PUBLISHED', 'Published'),
  archived('ARCHIVED', 'Archived');

  const NewsPostStatus(this.value, this.label);

  final String value;
  final String label;

  static NewsPostStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final status in NewsPostStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    return NewsPostStatus.draft;
  }
}
