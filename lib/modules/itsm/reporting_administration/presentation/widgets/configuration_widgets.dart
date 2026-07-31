import 'package:flutter/material.dart';

import '../../../shared/domain/itsm_common.dart';
import '../../domain/configuration_common.dart';
import '../reporting_administration_strings.dart';
import 'reporting_page_shell.dart';

class ConfigurationStatusBadge extends StatelessWidget {
  const ConfigurationStatusBadge(this.state, {super.key});
  final ItsmPublicationState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (state) {
      ItsmPublicationState.draft => colors.tertiary,
      ItsmPublicationState.published => colors.primary,
      ItsmPublicationState.retired => colors.outline,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(state.value.toUpperCase()),
      side: BorderSide(color: color.withOpacity(.35)),
    );
  }
}

class ConfigurationList extends StatelessWidget {
  const ConfigurationList(
      {required this.children,
      super.key,
      this.emptyLabel = 'No configuration found.'});
  final List<Widget> children;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) => children.isEmpty
      ? ReportingPanel(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(32), child: Text(emptyLabel))))
      : ReportingPanel(child: Column(children: children));
}

class VersionHistoryPanel extends StatelessWidget {
  const VersionHistoryPanel(
      {required this.versions, super.key, this.onSelected});
  final List<ConfigurationVersionSummary> versions;
  final ValueChanged<ConfigurationVersionSummary>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return ReportingPanel(
      title: strings.value('versions'),
      child: Column(
        children: versions
            .map((version) => ListTile(
                  onTap: onSelected == null ? null : () => onSelected!(version),
                  leading: CircleAvatar(child: Text('${version.version}')),
                  title: Text('${strings.value('version')} ${version.version}'),
                  subtitle: Text(
                      version.isImmutable ? 'Immutable' : 'Editable draft'),
                  trailing: ConfigurationStatusBadge(version.state),
                ))
            .toList(growable: false),
      ),
    );
  }
}

class WorkflowValidationPanel extends StatelessWidget {
  const WorkflowValidationPanel({required this.issues, super.key});
  final List<Object> issues;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return ReportingPanel(
      title: issues.isEmpty
          ? strings.value('validationPassed')
          : strings.value('validationIssues'),
      child: issues.isEmpty
          ? ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(strings.value('validationPassedLong')))
          : Column(
              children: issues
                  .map((issue) => ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text('$issue')))
                  .toList(growable: false)),
    );
  }
}
