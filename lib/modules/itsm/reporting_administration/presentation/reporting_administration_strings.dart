import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/widgets.dart';

class ReportingAdministrationStrings {
  const ReportingAdministrationStrings._(this._l10n);

  factory ReportingAdministrationStrings.of(BuildContext context) =>
      ReportingAdministrationStrings._(S.maybeOf(context));

  final S? _l10n;

  String value(String key) {
    final namespaced =
        'itsmReporting${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
    final localized = _l10n?.lookup(namespaced) ?? namespaced;
    return localized == namespaced ? (_fallbacks[key] ?? key) : localized;
  }
}

const _fallbacks = <String, String>{
  'title': 'Reporting & Administration',
  'subtitle': 'Trusted dashboards, service controls and audit oversight.',
  'dashboards': 'Dashboards',
  'dashboardsDescription': 'Operational and executive performance snapshots.',
  'sla': 'SLA policies',
  'slaDescription': 'Business calendars, targets, warnings and escalations.',
  'catalogue': 'Service catalogue',
  'catalogueDescription': 'Version and publish request offerings.',
  'workflows': 'Workflows',
  'workflowsDescription': 'Validate and publish immutable workflow versions.',
  'audit': 'Audit logs',
  'auditDescription': 'Bounded, append-only operational evidence.',
  'operationalDashboard': 'Operational dashboard',
  'executiveDashboard': 'Executive dashboard',
  'incidentDashboard': 'Incident reporting',
  'readOnly': 'Read-only',
  'accessDenied': 'Access denied',
  'accessDeniedDescription':
      'You do not have access to Reporting & Administration.',
  'loading': 'Loading trusted data...',
  'error': 'The trusted data could not be loaded.',
  'empty': 'No data is available for this view.',
  'retry': 'Retry',
  'incompleteSnapshot': 'Snapshot reconciliation is still in progress.',
  'generatedAt': 'Generated',
  'highlights': 'Highlights',
  'breakdowns': 'Breakdowns',
  'trends': 'Trends',
  'createDraft': 'Create draft',
  'publish': 'Publish',
  'retire': 'Retire',
  'validate': 'Validate',
  'draft': 'Draft',
  'published': 'Published',
  'retired': 'Retired',
  'versions': 'Version history',
  'immutable': 'Published versions are immutable',
  'validationPassed': 'Ready to publish',
  'validationIssues': 'Validation issues',
  'auditFilters': 'Audit filters',
  'from': 'From',
  'to': 'To',
  'dimension': 'Dimension',
  'value': 'Value',
  'apply': 'Apply',
  'export': 'Request export',
  'loadMore': 'Load more',
  'noEvents': 'No audit events match these filters.',
  'configurationReadOnly':
      'ADMIN can inspect published and retired versions only.',
  'auditExportQueued': 'Audit export queued.',
  'noData': 'No data',
  'none': 'None',
  'saveDraft': 'Save draft',
  'policyName': 'Policy name',
  'timeZone': 'IANA time zone',
  'responseTarget': 'Response target (minutes)',
  'resolutionTarget': 'Resolution target (minutes)',
  'weekdayStart': 'Weekday start (minutes after midnight)',
  'weekdayEnd': 'Weekday end (minutes after midnight)',
  'warningThreshold': 'Warning threshold (0-1)',
  'holidays': 'Holidays (YYYY-MM-DD, comma separated)',
  'pauseStatuses': 'Pause statuses (comma separated)',
  'businessHoursOrder': 'Business hours end must follow start.',
  'requiredField': 'This field is required.',
  'positiveNumber': 'Enter a positive number.',
  'minutesRange': 'Enter a value from 0 to 1440.',
  'thresholdRange': 'Enter a value between 0 and 1.',
  'nameEnglish': 'Name (English)',
  'nameFrench': 'Name (French)',
  'descriptionEnglish': 'Description (English)',
  'descriptionFrench': 'Description (French)',
  'categoryId': 'Category ID',
  'workflowId': 'Published workflow ID',
  'workflowVersion': 'Workflow version',
  'slaPolicyId': 'Published SLA policy ID',
  'slaVersion': 'SLA policy version',
  'version': 'Version',
  'validationPassedLong': 'All local validation checks passed.',
  'statesTransitions': 'States and transitions',
  'transitions': 'Transitions',
  'terminal': 'Terminal',
  'editDraft': 'Edit and validate this draft version.',
  'event': 'Event',
  'occurred': 'Occurred',
  'actor': 'Actor',
  'entity': 'Entity',
  'correlation': 'Correlation',
  'confidentiality': 'Confidentiality',
  'transition': 'Transition',
  'before': 'Before',
  'after': 'After',
};
