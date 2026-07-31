import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/sla.dart';
import 'configuration_common.dart';

class SlaPolicyConfiguration {
  SlaPolicyConfiguration({
    required this.id,
    required this.name,
    required this.workItemType,
    required this.status,
    required this.latestVersion,
    required this.updatedAt,
    this.currentPublishedVersion,
    this.serviceId,
    this.priority,
  }) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('SLA policy ID and name are required.');
    }
  }

  final String id;
  final String name;
  final ItsmWorkItemType workItemType;
  final ItsmPublicationState status;
  final int latestVersion;
  final int? currentPublishedVersion;
  final String? serviceId;
  final ItsmPriority? priority;
  final DateTime updatedAt;

  factory SlaPolicyConfiguration.fromMap(String id, Map<String, Object?> map) {
    final type = ItsmWorkItemType.tryParse(map['workItemType']);
    if (type == null) {
      throw const FormatException('Unknown SLA work-item type.');
    }
    return SlaPolicyConfiguration(
      id: id,
      name: _localizedLabel(map['name'], id),
      workItemType: type,
      status: publicationState(map['status']),
      latestVersion: configurationInt(map['latestVersion'], 1),
      currentPublishedVersion: map['currentPublishedVersion'] == null
          ? null
          : configurationInt(map['currentPublishedVersion']),
      serviceId: _nullable(map['serviceId']),
      priority: map['priority'] == null
          ? null
          : ItsmPriority.fromValue(map['priority']),
      updatedAt: configurationDate(map['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class SlaPolicyVersionConfiguration {
  SlaPolicyVersionConfiguration({
    required this.policyId,
    required this.versionId,
    required this.version,
    required this.state,
    required this.name,
    required this.workItemType,
    required this.timeZone,
    required this.responseTarget,
    required this.resolutionTarget,
    required this.calendar,
    required this.warningThreshold,
    required this.createdAt,
    required this.createdBy,
    Iterable<String> pauseStatuses = const [],
    this.fulfilmentTarget,
    this.serviceId,
    this.priority,
    this.escalationEvent,
    this.escalationGroupId,
    this.publishedAt,
    this.revision = 0,
  }) : pauseStatuses = Set<String>.unmodifiable(
          pauseStatuses
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );

  final String policyId;
  final String versionId;
  final int version;
  final ItsmPublicationState state;
  final String name;
  final ItsmWorkItemType workItemType;
  final String timeZone;
  final Duration responseTarget;
  final Duration resolutionTarget;
  final Duration? fulfilmentTarget;
  final BusinessCalendar calendar;
  final double warningThreshold;
  final Set<String> pauseStatuses;
  final String? serviceId;
  final ItsmPriority? priority;
  final String? escalationEvent;
  final String? escalationGroupId;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? publishedAt;
  final int revision;

  bool get isImmutable => state != ItsmPublicationState.draft;

  ConfigurationValidationResult validateForPublication() {
    final issues = <ConfigurationValidationIssue>[];
    if (name.trim().isEmpty) {
      issues.add(const ConfigurationValidationIssue(
          'name_required', 'A name is required.',
          field: 'name'));
    }
    if (responseTarget <= Duration.zero || resolutionTarget <= Duration.zero) {
      issues.add(const ConfigurationValidationIssue(
          'targets_positive', 'SLA targets must be positive.'));
    }
    if (resolutionTarget < responseTarget) {
      issues.add(const ConfigurationValidationIssue(
          'target_order', 'Resolution target cannot precede response target.'));
    }
    if (fulfilmentTarget != null && fulfilmentTarget! < responseTarget) {
      issues.add(const ConfigurationValidationIssue('fulfilment_target_order',
          'Fulfilment target cannot precede response target.'));
    }
    if (!_ianaTimeZone.hasMatch(timeZone)) {
      issues.add(const ConfigurationValidationIssue(
          'invalid_timezone', 'Use an IANA time zone.',
          field: 'timeZone'));
    }
    if (warningThreshold <= 0 || warningThreshold >= 1) {
      issues.add(const ConfigurationValidationIssue(
          'invalid_warning', 'Warning threshold must be between 0 and 1.'));
    }
    if (escalationEvent != null && escalationEvent!.trim().isEmpty) {
      issues.add(const ConfigurationValidationIssue(
          'invalid_escalation', 'Escalation event cannot be blank.'));
    }
    return ConfigurationValidationResult(issues);
  }

  Map<String, Object?> toCommandDefinition() => {
        'name': {'en': name, 'fr': name},
        'workItemType': workItemType.value,
        'timeZone': timeZone,
        'responseTargetMinutes': responseTarget.inMinutes,
        'resolutionTargetMinutes': resolutionTarget.inMinutes,
        if (fulfilmentTarget != null)
          'fulfilmentTargetMinutes': fulfilmentTarget!.inMinutes,
        'warningThreshold': warningThreshold,
        'pauseStates': pauseStatuses.toList(growable: false),
        if (serviceId != null) 'serviceId': serviceId,
        if (priority != null) 'priority': priority!.value,
        'weeklyWindows': {
          for (final entry in calendar.weeklyWindows.entries)
            entry.key.toString(): entry.value
                .map((window) => {
                      'start': _formatBusinessTime(window.start),
                      'end': _formatBusinessTime(window.end),
                    })
                .toList(growable: false),
        },
        'holidays': calendar.holidayKeys.toList(growable: false),
        'escalationTargets': [
          if (escalationEvent != null)
            {
              'eventName': escalationEvent,
              'assignmentGroupId': escalationGroupId,
              'userId': null,
              'atPercent': 100,
            },
        ],
      };

  Map<String, Object?> toCommandPayload() => toCommandDefinition();

  factory SlaPolicyVersionConfiguration.fromMap(
    String policyId,
    String versionId,
    Map<String, Object?> map,
  ) {
    final nestedDefinition = configurationMap(map['definition']);
    final definition = nestedDefinition.isEmpty ? map : nestedDefinition;
    final calendarMap = configurationMap(
      definition['calendarSnapshot'] ?? definition['calendar'],
    );
    final windowsMap = configurationMap(
      definition['weeklyWindows'] ?? calendarMap['weeklyWindows'],
    );
    final weeklyWindows = <int, List<BusinessHoursWindow>>{};
    for (final entry in windowsMap.entries) {
      final weekday = int.tryParse(entry.key);
      if (weekday == null) continue;
      weeklyWindows[weekday] = configurationList(entry.value)
          .map(configurationMap)
          .map((window) => BusinessHoursWindow(
                start: _businessTime(window['start'], window['startMinutes']),
                end: _businessTime(window['end'], window['endMinutes']),
              ))
          .toList(growable: false);
    }
    final type = ItsmWorkItemType.tryParse(definition['workItemType']);
    if (type == null) {
      throw const FormatException('Unknown SLA work-item type.');
    }
    return SlaPolicyVersionConfiguration(
      policyId: policyId,
      versionId: versionId,
      version: configurationInt(map['version'], 1),
      state: publicationState(map['status'] ?? map['state']),
      name: _localizedLabel(definition['name']),
      workItemType: type,
      timeZone: configurationString(definition['timeZone'], 'UTC'),
      responseTarget: Duration(
          minutes: configurationInt(definition['responseTargetMinutes'])),
      resolutionTarget: Duration(
          minutes: configurationInt(definition['resolutionTargetMinutes'])),
      fulfilmentTarget: definition['fulfilmentTargetMinutes'] == null
          ? null
          : Duration(
              minutes: configurationInt(definition['fulfilmentTargetMinutes'])),
      calendar: BusinessCalendar(
        weeklyWindows: weeklyWindows,
        holidays: configurationList(
          definition['holidays'] ?? calendarMap['holidays'],
        ).map(configurationString).map(DateTime.tryParse).whereType<DateTime>(),
      ),
      warningThreshold:
          configurationDouble(definition['warningThreshold'], 0.8),
      pauseStatuses: configurationList(
        definition['pauseStates'] ?? definition['pauseStatuses'],
      ).map(configurationString),
      serviceId: _nullable(definition['serviceId']),
      priority: definition['priority'] == null
          ? null
          : ItsmPriority.fromValue(definition['priority']),
      escalationEvent: _nullable(definition['escalationEvent']),
      escalationGroupId: _nullable(definition['escalationGroupId']),
      createdAt: configurationDate(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdBy: configurationString(map['createdBy'], 'unknown'),
      publishedAt: configurationDate(map['publishedAt']),
      revision: configurationInt(map['revision']),
    );
  }
}

final RegExp _ianaTimeZone =
    RegExp(r'^(UTC|[A-Za-z_]+(?:/[A-Za-z0-9_+\-]+)+)$');
String? _nullable(Object? value) {
  final result = configurationString(value);
  return result.isEmpty ? null : result;
}

String _localizedLabel(Object? value, [String fallback = '']) {
  final localized = configurationMap(value);
  return configurationString(
    localized['en'] ?? localized['fr'] ?? value,
    fallback,
  );
}

Duration _businessTime(Object? formatted, Object? minutes) {
  final parsedMinutes = configurationInt(minutes, -1);
  if (parsedMinutes >= 0) return Duration(minutes: parsedMinutes);
  final parts = configurationString(formatted).split(':');
  if (parts.length != 2) return Duration.zero;
  return Duration(
    hours: int.tryParse(parts.first) ?? 0,
    minutes: int.tryParse(parts.last) ?? 0,
  );
}

String _formatBusinessTime(Duration value) {
  final hours = value.inHours.toString().padLeft(2, '0');
  final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}
