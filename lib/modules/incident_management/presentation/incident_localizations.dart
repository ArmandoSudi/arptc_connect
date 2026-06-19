import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';

String localizedIncidentRoleLabel(S l10n, IncidentRole role) {
  switch (role) {
    case IncidentRole.none:
      return l10n.incidentRoleNoAccess;
    case IncidentRole.user:
      return l10n.incidentRoleUser;
    case IncidentRole.manager:
      return l10n.incidentRoleManager;
    case IncidentRole.admin:
      return l10n.incidentRoleAdmin;
  }
}

String localizedIncidentStatusLabel(S l10n, IncidentStatus status) {
  switch (status) {
    case IncidentStatus.open:
      return l10n.incidentStatusOpen;
    case IncidentStatus.categorized:
      return l10n.incidentStatusCategorized;
    case IncidentStatus.assigned:
      return l10n.incidentStatusAssigned;
    case IncidentStatus.inProgress:
      return l10n.incidentStatusInProgress;
    case IncidentStatus.resolved:
      return l10n.incidentStatusResolved;
    case IncidentStatus.closed:
      return l10n.incidentStatusClosed;
    case IncidentStatus.archived:
      return l10n.incidentStatusArchived;
    case IncidentStatus.cancelled:
      return l10n.incidentStatusCancelled;
  }
}

String localizedIncidentLifecycleLabel(
  S l10n,
  IncidentLifecycleState lifecycleState,
) {
  switch (lifecycleState) {
    case IncidentLifecycleState.active:
      return l10n.incidentLifecycleActive;
    case IncidentLifecycleState.closed:
      return l10n.incidentLifecycleClosed;
    case IncidentLifecycleState.archived:
      return l10n.incidentLifecycleArchived;
  }
}

String localizedIncidentImpactLabel(S l10n, IncidentImpact impact) {
  switch (impact) {
    case IncidentImpact.low:
      return l10n.incidentImpactLow;
    case IncidentImpact.medium:
      return l10n.incidentImpactMedium;
    case IncidentImpact.high:
      return l10n.incidentImpactHigh;
  }
}

String localizedIncidentUrgencyLabel(S l10n, IncidentUrgency urgency) {
  switch (urgency) {
    case IncidentUrgency.low:
      return l10n.incidentUrgencyLow;
    case IncidentUrgency.medium:
      return l10n.incidentUrgencyMedium;
    case IncidentUrgency.high:
      return l10n.incidentUrgencyHigh;
  }
}

String localizedIncidentPriorityLabel(S l10n, IncidentPriority priority) {
  switch (priority) {
    case IncidentPriority.none:
      return l10n.incidentPriorityUnprioritized;
    case IncidentPriority.p1:
      return IncidentPriority.p1.label;
    case IncidentPriority.p2:
      return IncidentPriority.p2.label;
    case IncidentPriority.p3:
      return IncidentPriority.p3.label;
    case IncidentPriority.p4:
      return IncidentPriority.p4.label;
  }
}
