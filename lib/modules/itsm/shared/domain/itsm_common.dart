enum ItsmRole {
  user('USER'),
  manager('MANAGER'),
  admin('ADMIN');

  const ItsmRole(this.value);

  final String value;

  static ItsmRole? tryParse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    for (final role in values) {
      if (role.value == normalized) return role;
    }
    return null;
  }
}

enum ItsmWorkItemType {
  incident('incident'),
  serviceRequest('service_request'),
  changeRequest('change_request'),
  securityFinding('security_finding'),
  securityException('security_exception');

  const ItsmWorkItemType(this.value);

  final String value;

  static ItsmWorkItemType? tryParse(Object? value) {
    final normalized = _normalize(value);
    for (final type in values) {
      if (type.value == normalized) return type;
    }
    return null;
  }
}

enum ItsmLifecycleState {
  active('active'),
  closed('closed'),
  archived('archived'),
  cancelled('cancelled');

  const ItsmLifecycleState(this.value);

  final String value;

  static ItsmLifecycleState? tryParse(Object? value) {
    final normalized = _normalize(value);
    for (final state in values) {
      if (state.value == normalized) return state;
    }
    return null;
  }
}

enum ItsmPriority {
  p1('P1', 1),
  p2('P2', 2),
  p3('P3', 3),
  p4('P4', 4),
  unprioritized('', 5);

  const ItsmPriority(this.value, this.sortOrder);

  final String value;
  final int sortOrder;

  static ItsmPriority fromValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase() ?? '';
    for (final priority in values) {
      if (priority.value == normalized) return priority;
    }
    return ItsmPriority.unprioritized;
  }
}

enum ItsmImpact {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ItsmImpact(this.value);

  final String value;
}

enum ItsmUrgency {
  low('low'),
  medium('medium'),
  high('high');

  const ItsmUrgency(this.value);

  final String value;
}

enum ItsmConfidentiality {
  employee('employee'),
  internal('internal'),
  restricted('restricted');

  const ItsmConfidentiality(this.value);

  final String value;

  static ItsmConfidentiality fromValue(Object? value) {
    final normalized = _normalize(value);
    for (final confidentiality in values) {
      if (confidentiality.value == normalized) return confidentiality;
    }
    return ItsmConfidentiality.internal;
  }
}

enum ItsmPublicationState {
  draft('draft'),
  published('published'),
  retired('retired');

  const ItsmPublicationState(this.value);

  final String value;
}

String _normalize(Object? value) {
  return value?.toString().trim().toLowerCase().replaceAll('-', '_') ?? '';
}
