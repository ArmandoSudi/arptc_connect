import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:flutter/material.dart';

class OrganizationPlacementSelection {
  const OrganizationPlacementSelection({
    this.departmentId,
    this.serviceId,
    this.bureauId,
    this.assignAsHead = false,
  });

  final String? departmentId;
  final String? serviceId;
  final String? bureauId;
  final bool assignAsHead;

  String? get selectedUnitId => bureauId ?? serviceId ?? departmentId;

  OrganizationUnitType? get selectedUnitType {
    if (bureauId != null) return OrganizationUnitType.bureau;
    if (serviceId != null) return OrganizationUnitType.service;
    if (departmentId != null) return OrganizationUnitType.department;
    return null;
  }
}

class OrganizationUnitHierarchySelector extends StatefulWidget {
  const OrganizationUnitHierarchySelector({
    required this.units,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final List<OrganizationUnit> units;
  final ValueChanged<OrganizationPlacementSelection> onChanged;
  final bool enabled;

  @override
  State<OrganizationUnitHierarchySelector> createState() =>
      _OrganizationUnitHierarchySelectorState();
}

class _OrganizationUnitHierarchySelectorState
    extends State<OrganizationUnitHierarchySelector> {
  String? _departmentId;
  String? _serviceId;
  String? _bureauId;
  bool _assignAsHead = false;

  List<OrganizationUnit> get _activeUnits =>
      widget.units.where((unit) => unit.isActive).toList(growable: false);

  List<OrganizationUnit> get _departments => _sorted(
        _activeUnits
            .where((unit) => unit.type == OrganizationUnitType.department),
      );

  List<OrganizationUnit> get _services => _sorted(
        _activeUnits.where(
          (unit) =>
              unit.type == OrganizationUnitType.service &&
              unit.parentUnitId == _departmentId,
        ),
      );

  List<OrganizationUnit> get _bureaux => _sorted(
        _activeUnits.where(
          (unit) =>
              unit.type == OrganizationUnitType.bureau &&
              unit.parentUnitId == _serviceId,
        ),
      );

  OrganizationPlacementSelection get _selection =>
      OrganizationPlacementSelection(
        departmentId: _departmentId,
        serviceId: _serviceId,
        bureauId: _bureauId,
        assignAsHead: _assignAsHead,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return FormField<OrganizationPlacementSelection>(
      initialValue: _selection,
      validator: (selection) {
        if (selection?.departmentId == null) {
          return l10n.lookup('umRequiredField');
        }
        if (selection?.bureauId == null && selection?.assignAsHead != true) {
          return l10n.lookup('umSelectBureauOrLeadership');
        }
        return null;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('organization-department-dropdown'),
            value: _departmentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.selectDepartment),
            items: _departments
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit.id,
                    child: Text(unit.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.enabled
                ? (value) => _update(field, () {
                      _departmentId = value;
                      _serviceId = null;
                      _bureauId = null;
                      _assignAsHead = false;
                    })
                : null,
          ),
          if (_departmentId != null) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('organization-service-dropdown'),
              value: _serviceId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.selectService,
                suffixIcon: _serviceId == null
                    ? null
                    : IconButton(
                        key: const Key('clear-organization-service'),
                        tooltip: l10n.clear,
                        onPressed: widget.enabled
                            ? () => _update(field, () {
                                  _serviceId = null;
                                  _bureauId = null;
                                  _assignAsHead = false;
                                })
                            : null,
                        icon: const Icon(Icons.clear),
                      ),
              ),
              items: _services
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit.id,
                      child: Text(unit.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.enabled
                  ? (value) => _update(field, () {
                        _serviceId = value;
                        _bureauId = null;
                        _assignAsHead = false;
                      })
                  : null,
            ),
          ],
          if (_serviceId != null) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('organization-bureau-dropdown'),
              value: _bureauId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.selectBureau,
                suffixIcon: _bureauId == null
                    ? null
                    : IconButton(
                        key: const Key('clear-organization-bureau'),
                        tooltip: l10n.clear,
                        onPressed: widget.enabled
                            ? () => _update(field, () {
                                  _bureauId = null;
                                  _assignAsHead = false;
                                })
                            : null,
                        icon: const Icon(Icons.clear),
                      ),
              ),
              items: _bureaux
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit.id,
                      child: Text(unit.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.enabled
                  ? (value) => _update(field, () {
                        _bureauId = value;
                        _assignAsHead = false;
                      })
                  : null,
            ),
          ],
          if (_departmentId != null) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('organization-leadership-checkbox'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _assignAsHead,
              title: Text(_leadershipLabel(l10n, _selection.selectedUnitType!)),
              onChanged: widget.enabled
                  ? (value) => _update(
                        field,
                        () => _assignAsHead = value ?? false,
                      )
                  : null,
            ),
          ],
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _update(
    FormFieldState<OrganizationPlacementSelection> field,
    VoidCallback change,
  ) {
    setState(change);
    field.didChange(_selection);
    widget.onChanged(_selection);
  }
}

List<OrganizationUnit> _sorted(Iterable<OrganizationUnit> units) {
  final result = units.toList(growable: false);
  result.sort((left, right) {
    final byName = left.nameLower.compareTo(right.nameLower);
    return byName != 0 ? byName : left.id.compareTo(right.id);
  });
  return result;
}

String _leadershipLabel(S l10n, OrganizationUnitType type) => switch (type) {
      OrganizationUnitType.department => l10n.headOfDepartment,
      OrganizationUnitType.service => l10n.headOfService,
      OrganizationUnitType.bureau => l10n.headOfBureau,
      OrganizationUnitType.custom => l10n.lookup('umAssignHead'),
    };
