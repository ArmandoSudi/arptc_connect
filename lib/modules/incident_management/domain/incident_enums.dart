enum IncidentRole {
  none('NONE', 'No access'),
  user('USER', 'User'),
  manager('MANAGER', 'Manager'),
  admin('ADMIN', 'Admin');

  const IncidentRole(this.value, this.label);

  final String value;
  final String label;

  static IncidentRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final role in IncidentRole.values) {
      if (role.value == normalized) {
        return role;
      }
    }
    return IncidentRole.none;
  }
}

enum IncidentStatus {
  open('open', 'Open'),
  categorized('categorized', 'Categorized'),
  assigned('assigned', 'Assigned'),
  inProgress('in_progress', 'In progress'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed'),
  archived('archived', 'Archived'),
  cancelled('cancelled', 'Cancelled');

  const IncidentStatus(this.value, this.label);

  final String value;
  final String label;

  static IncidentStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final status in IncidentStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    return IncidentStatus.open;
  }
}

enum IncidentLifecycleState {
  active('active', 'Active'),
  closed('closed', 'Closed'),
  archived('archived', 'Archived');

  const IncidentLifecycleState(this.value, this.label);

  final String value;
  final String label;

  static IncidentLifecycleState fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final state in IncidentLifecycleState.values) {
      if (state.value == normalized) {
        return state;
      }
    }
    return IncidentLifecycleState.active;
  }
}

enum IncidentImpact {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const IncidentImpact(this.value, this.label);

  final String value;
  final String label;

  static IncidentImpact? fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final impact in IncidentImpact.values) {
      if (impact.value == normalized) {
        return impact;
      }
    }
    return null;
  }
}

enum IncidentUrgency {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High');

  const IncidentUrgency(this.value, this.label);

  final String value;
  final String label;

  static IncidentUrgency? fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final urgency in IncidentUrgency.values) {
      if (urgency.value == normalized) {
        return urgency;
      }
    }
    return null;
  }
}

enum IncidentPriority {
  none('', 'Unprioritized'),
  p1('P1', 'P1'),
  p2('P2', 'P2'),
  p3('P3', 'P3'),
  p4('P4', 'P4');

  const IncidentPriority(this.value, this.label);

  final String value;
  final String label;

  static IncidentPriority fromValue(String? value) {
    final rawValue = (value ?? '').trim();
    final normalized = rawValue.toUpperCase();
    final legacyValue = rawValue.toLowerCase();

    switch (normalized) {
      case 'P1':
        return IncidentPriority.p1;
      case 'P2':
        return IncidentPriority.p2;
      case 'P3':
        return IncidentPriority.p3;
      case 'P4':
        return IncidentPriority.p4;
    }

    switch (legacyValue) {
      case 'critical':
        return IncidentPriority.p1;
      case 'high':
        return IncidentPriority.p2;
      case 'medium':
        return IncidentPriority.p3;
      case 'low':
        return IncidentPriority.p4;
    }
    return IncidentPriority.none;
  }
}

IncidentPriority calculateIncidentPriority({
  required String impact,
  required String urgency,
}) {
  final resolvedImpact = IncidentImpact.fromValue(impact);
  final resolvedUrgency = IncidentUrgency.fromValue(urgency);

  if (resolvedImpact == null || resolvedUrgency == null) {
    return IncidentPriority.none;
  }

  if (resolvedImpact == IncidentImpact.high &&
      resolvedUrgency == IncidentUrgency.high) {
    return IncidentPriority.p1;
  }

  if (resolvedImpact == IncidentImpact.high ||
      resolvedUrgency == IncidentUrgency.high) {
    return IncidentPriority.p2;
  }

  if (resolvedImpact == IncidentImpact.medium ||
      resolvedUrgency == IncidentUrgency.medium) {
    return IncidentPriority.p3;
  }

  return IncidentPriority.p4;
}
