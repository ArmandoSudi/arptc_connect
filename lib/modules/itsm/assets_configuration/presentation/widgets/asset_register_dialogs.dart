import 'dart:async';
import 'dart:math' as math;

import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../../shared/domain/pagination.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../../domain/asset_assignee.dart';
import '../../domain/asset_parameter.dart';
import '../assets_configuration_error_message.dart';
import '../assets_configuration_strings.dart';

Future<void> showAssetRegistrationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final parameters = await ref.read(
      assetParametersProvider(PageRequest.maximumLimit).future,
    );
    if (!context.mounted) return;
    final succeeded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssetRegistrationDialog(
        parameters: parameters,
        onSubmit: (fields) => _registerAsset(ref, fields),
      ),
    );
    if (succeeded == true && context.mounted) {
      _showSuccess(
        context,
        AssetsConfigurationStrings.of(context).assetRegisteredSuccessfully,
      );
    }
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

Future<void> showAssetParametersDialog(
  BuildContext context,
  WidgetRef ref,
) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AssetParametersDialog(),
    );

Future<void> showAssignAssetToAgentDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  try {
    final succeeded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssetAssignmentDialog(
        onSubmit: (assignee, assignedAt) => _operateAsset(
          ref,
          detail.summary.id,
          'assign',
          {
            'assignedUserId': assignee.id,
            'assignedAt': _isoDate(assignedAt),
            if (assignee.departmentId.isNotEmpty)
              'departmentId': assignee.departmentId,
          },
        ),
      ),
    );
    if (succeeded == true && context.mounted) {
      _showSuccess(
        context,
        AssetsConfigurationStrings.of(context).assetAssignedSuccessfully,
      );
    }
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

Future<void> showChangeAssetStateDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail, {
  List<AssetParameter>? availableStates,
}) async {
  try {
    final states = availableStates ??
        (await ref.read(
          assetParametersProvider(PageRequest.maximumLimit).future,
        ))
            .where((parameter) => parameter.type == AssetParameterType.state)
            .toList(growable: false);
    if (!context.mounted) return;
    final succeeded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssetStateDialog(
        states: states,
        currentStateName: detail.stateName.isNotEmpty
            ? detail.stateName
            : detail.summary.stateName,
        onSubmit: (state, observation) => _operateAsset(
          ref,
          detail.summary.id,
          'change_state',
          {
            'stateId': state.id,
            'stateName': state.name,
            'observation': observation,
          },
        ),
      ),
    );
    if (succeeded == true && context.mounted) {
      _showSuccess(
        context,
        AssetsConfigurationStrings.of(context).assetStateUpdated,
      );
    }
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

Future<void> showDecommissionAssetDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  final succeeded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AssetDecommissionDialog(
      onSubmit: (observation) => _operateAsset(
        ref,
        detail.summary.id,
        'decommission',
        {'observation': observation},
      ),
    ),
  );
  if (succeeded == true && context.mounted) {
    _showSuccess(
      context,
      AssetsConfigurationStrings.of(context).assetDecommissionedSuccessfully,
    );
  }
}

class _AssetRegistrationDialog extends ConsumerStatefulWidget {
  const _AssetRegistrationDialog({
    required this.parameters,
    required this.onSubmit,
  });

  final List<AssetParameter> parameters;
  final Future<void> Function(Map<String, Object?> fields) onSubmit;

  @override
  ConsumerState<_AssetRegistrationDialog> createState() =>
      _AssetRegistrationDialogState();
}

class _AssetRegistrationDialogState
    extends ConsumerState<_AssetRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _serialNumber = TextEditingController();
  final _productNumber = TextEditingController();
  final _acquisitionDate = TextEditingController();
  final _assignmentDate = TextEditingController(text: _isoDate(DateTime.now()));
  final _observation = TextEditingController();
  AssetParameter? _category;
  AssetParameter? _location;
  AssetParameter? _state;
  AssetAssignee? _assignee;
  List<AssetAssignee> _lastAssigneeOptions = const [];
  Timer? _assigneeSearchDebounce;
  String _assigneeSearch = '';
  bool _submitting = false;
  String? _error;

  List<AssetParameter> _parameters(AssetParameterType type) => widget.parameters
      .where((parameter) => parameter.type == type)
      .toList(growable: false);

  bool get _hasRequiredParameters =>
      _parameters(AssetParameterType.category).isNotEmpty &&
      _parameters(AssetParameterType.state).isNotEmpty;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _serialNumber.dispose();
    _productNumber.dispose();
    _acquisitionDate.dispose();
    _assignmentDate.dispose();
    _observation.dispose();
    _assigneeSearchDebounce?.cancel();
    super.dispose();
  }

  void _queueAssigneeSearch(String value) {
    if (_assignee != null && value.trim() != _assignee!.displayName) {
      setState(() => _assignee = null);
    }
    _assigneeSearchDebounce?.cancel();
    _assigneeSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final normalized = value.trim().toLowerCase();
      if (normalized != _assigneeSearch) {
        setState(() => _assigneeSearch = normalized);
      }
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) controller.text = _isoDate(date);
  }

  Future<void> _submit() async {
    if (_submitting || !_hasRequiredParameters) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final generatedId =
        'asset-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final assetTag = _serialNumber.text.trim().isNotEmpty
        ? _serialNumber.text.trim()
        : _productNumber.text.trim();
    try {
      await widget.onSubmit({
        'assetId': generatedId,
        'assetTag': assetTag,
        'brand': _brand.text.trim(),
        'model': _model.text.trim(),
        'serialNumber': _serialNumber.text.trim(),
        'productNumber': _productNumber.text.trim(),
        'categoryId': _category!.id,
        'categoryName': _category!.name,
        'type': _category!.name,
        if (_location != null) ...{
          'locationId': _location!.id,
          'locationName': _location!.name,
        },
        'stateId': _state!.id,
        'stateName': _state!.name,
        'condition': 'good',
        'acquisitionDate': _acquisitionDate.text.trim(),
        if (_assignee != null) ...{
          'assignedUserId': _assignee!.id,
          'assignedAt': _assignmentDate.text.trim(),
        },
        if (_observation.text.trim().isNotEmpty)
          'observation': _observation.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final assignees = ref.watch(
      assetAssigneeSearchProvider(
        AssetAssigneeSearchQuery(search: _assigneeSearch),
      ),
    );
    final latestAssigneeOptions = assignees.asData?.value;
    if (latestAssigneeOptions != null) {
      _lastAssigneeOptions = latestAssigneeOptions;
    }
    return AlertDialog(
      title: Text(strings.registerNewAsset),
      content: SizedBox(
        width: _dialogWidth(context),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_hasRequiredParameters)
                  _MessageBox(
                    message: strings.configureAssetParametersFirst,
                    isError: true,
                  ),
                _ResponsiveFields(
                  children: [
                    _textField(_brand, strings.brand, required: true),
                    _textField(_model, strings.model, required: true),
                    _textField(
                      _serialNumber,
                      strings.serialNumber,
                      required: true,
                    ),
                    _textField(_productNumber, strings.productNumber),
                    _parameterDropdown(
                      label: strings.selectAssetCategory,
                      values: _parameters(AssetParameterType.category),
                      value: _category,
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    _parameterDropdown(
                      label: strings.selectAssetLocation,
                      values: _parameters(AssetParameterType.location),
                      value: _location,
                      required: false,
                      onChanged: (value) => setState(() => _location = value),
                    ),
                    _parameterDropdown(
                      label: strings.selectAssetState,
                      values: _parameters(AssetParameterType.state),
                      value: _state,
                      onChanged: (value) => setState(() => _state = value),
                    ),
                    _dateField(
                      _acquisitionDate,
                      strings.acquisitionDate,
                      required: true,
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  strings.optionalInitialAssignment,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.optionalInitialAssignmentHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Autocomplete<AssetAssignee>(
                  displayStringForOption: (agent) => agent.displayName,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return _lastAssigneeOptions;
                    return _lastAssigneeOptions.where(
                      (agent) =>
                          agent.displayName.toLowerCase().contains(query) ||
                          agent.email.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (agent) => setState(() => _assignee = agent),
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onFieldSubmitted,
                  ) =>
                      CommonTextInput(
                    label: strings.searchAgents,
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_submitting,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: assignees.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    onChanged: _queueAssigneeSearch,
                    onSubmitted: (_) => onFieldSubmitted(),
                    validator: (value) => value != null &&
                            value.trim().isNotEmpty &&
                            _assignee == null
                        ? strings.selectAgentFromResults
                        : null,
                  ),
                ),
                if (assignees.hasError) ...[
                  const SizedBox(height: 10),
                  _MessageBox(
                    message: _errorMessage(context, assignees.error!),
                    isError: true,
                  ),
                ] else if (!assignees.isLoading &&
                    _lastAssigneeOptions.isEmpty) ...[
                  const SizedBox(height: 10),
                  Text(strings.noActiveAgents),
                ],
                if (_assignee != null) ...[
                  const SizedBox(height: 14),
                  _dateField(
                    _assignmentDate,
                    strings.assignmentDate,
                    required: true,
                  ),
                ],
                const SizedBox(height: 20),
                CommonTextInput(
                  label: strings.observation,
                  controller: _observation,
                  isMultiline: true,
                  enabled: !_submitting,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _MessageBox(message: _error!, isError: true),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: _submitting || !_hasRequiredParameters ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_box_outlined),
          label: Text(strings.registerAsset),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) =>
      CommonTextInput(
        label: label,
        controller: controller,
        enabled: !_submitting,
        validator: required ? (value) => _required(context, value) : null,
      );

  Widget _dateField(
    TextEditingController controller,
    String label, {
    required bool required,
  }) =>
      CommonTextInput(
        label: label,
        controller: controller,
        readOnly: true,
        enabled: !_submitting,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
        onTap: () => _pickDate(controller),
        validator: required ? (value) => _required(context, value) : null,
      );

  Widget _parameterDropdown({
    required String label,
    required List<AssetParameter> values,
    required AssetParameter? value,
    required ValueChanged<AssetParameter?> onChanged,
    bool required = true,
  }) =>
      DropdownButtonFormField<AssetParameter>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (parameter) => DropdownMenuItem(
                value: parameter,
                child: Text(parameter.name),
              ),
            )
            .toList(growable: false),
        validator: required
            ? (selected) => selected == null
                ? AssetsConfigurationStrings.of(context).requiredField
                : null
            : null,
        onChanged: _submitting ? null : onChanged,
      );
}

class _AssetParametersDialog extends ConsumerStatefulWidget {
  const _AssetParametersDialog();

  @override
  ConsumerState<_AssetParametersDialog> createState() =>
      _AssetParametersDialogState();
}

class _AssetParametersDialogState
    extends ConsumerState<_AssetParametersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  AssetParameterType _type = AssetParameterType.category;
  AssetParameter? _editing;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _edit(AssetParameter parameter) {
    setState(() {
      _editing = parameter;
      _type = parameter.type;
      _name.text = parameter.name;
      _sortOrder.text = parameter.sortOrder.toString();
      _error = null;
    });
  }

  void _reset() {
    setState(() {
      _editing = null;
      _type = AssetParameterType.category;
      _name.clear();
      _sortOrder.text = '0';
      _submitting = false;
      _error = null;
    });
  }

  Future<void> _save({bool deactivate = false}) async {
    if (_submitting || (!deactivate && !_formKey.currentState!.validate())) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final editing = _editing;
    final id = editing?.id ??
        '${_type.name}-${_slug(_name.text)}-'
            '${DateTime.now().toUtc().millisecondsSinceEpoch}';
    try {
      await _manageConfiguration(
        ref,
        recordType: 'asset_parameter',
        operation: 'asset.parameter.save',
        recordId: id,
        fields: {
          'id': id,
          if (editing != null) 'expectedRevision': editing.revision,
          'type': editing?.type.name ?? _type.name,
          'name': editing?.name ?? _name.text.trim(),
          'sortOrder':
              editing?.sortOrder ?? (int.tryParse(_sortOrder.text.trim()) ?? 0),
          'isActive': !deactivate,
        },
      );
      if (!mounted) return;
      _reset();
      _showSuccess(
        context,
        AssetsConfigurationStrings.of(context).assetParameterSaved,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final parameters = ref.watch(
      assetParametersProvider(PageRequest.maximumLimit),
    );
    return AlertDialog(
      title: Text(strings.assetParameters),
      content: SizedBox(
        width: _dialogWidth(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.assetParametersDescription),
              const SizedBox(height: 16),
              parameters.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _MessageBox(
                  message: _errorMessage(context, error),
                  isError: true,
                ),
                data: (items) => _ParameterList(
                  parameters: items,
                  onEdit: _submitting ? null : _edit,
                ),
              ),
              const Divider(height: 32),
              Text(
                _editing == null
                    ? strings.addAssetParameter
                    : strings.editAssetParameter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: _ResponsiveFields(
                  children: [
                    DropdownButtonFormField<AssetParameterType>(
                      value: _type,
                      decoration: InputDecoration(labelText: strings.type),
                      items: AssetParameterType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(strings.assetParameterType(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _editing != null || _submitting
                          ? null
                          : (value) => setState(
                                () => _type = value ?? _type,
                              ),
                    ),
                    CommonTextInput(
                      label: strings.name,
                      controller: _name,
                      enabled: !_submitting,
                      validator: (value) => _required(context, value),
                    ),
                    CommonTextInput(
                      label: strings.assetParameterSortOrder,
                      controller: _sortOrder,
                      type: CommonTextInputType.number,
                      enabled: !_submitting,
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        return parsed == null || parsed < 0
                            ? strings.nonNegativeNumberRequired
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _MessageBox(message: _error!, isError: true),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (_editing != null)
                    TextButton(
                      onPressed: _submitting ? null : _reset,
                      child: Text(strings.cancel),
                    ),
                  if (_editing != null)
                    OutlinedButton.icon(
                      onPressed:
                          _submitting ? null : () => _save(deactivate: true),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(strings.deactivateAssetParameter),
                    ),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(strings.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

class _ParameterList extends StatelessWidget {
  const _ParameterList({required this.parameters, required this.onEdit});

  final List<AssetParameter> parameters;
  final ValueChanged<AssetParameter>? onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (parameters.isEmpty) {
      return Text(strings.configureAssetParametersFirst);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final parameter in parameters)
          ActionChip(
            avatar: Icon(_parameterIcon(parameter.type), size: 18),
            label: Text(
              '${strings.assetParameterType(parameter.type)}: '
              '${parameter.name}',
            ),
            onPressed: onEdit == null ? null : () => onEdit!(parameter),
          ),
      ],
    );
  }
}

class _AssetAssignmentDialog extends ConsumerStatefulWidget {
  const _AssetAssignmentDialog({
    required this.onSubmit,
  });

  final Future<void> Function(AssetAssignee assignee, DateTime assignedAt)
      onSubmit;

  @override
  ConsumerState<_AssetAssignmentDialog> createState() =>
      _AssetAssignmentDialogState();
}

class _AssetAssignmentDialogState
    extends ConsumerState<_AssetAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController(text: _isoDate(DateTime.now()));
  AssetAssignee? _assignee;
  List<AssetAssignee> _lastOptions = const [];
  Timer? _searchDebounce;
  String _search = '';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _date.dispose();
    super.dispose();
  }

  void _queueSearch(String value) {
    if (_assignee != null && value.trim() != _assignee!.displayName) {
      setState(() => _assignee = null);
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final normalized = value.trim().toLowerCase();
      if (normalized != _search) setState(() => _search = normalized);
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date.text) ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) _date.text = _isoDate(date);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_assignee!, DateTime.parse(_date.text));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final assignees = ref.watch(
      assetAssigneeSearchProvider(AssetAssigneeSearchQuery(search: _search)),
    );
    final latestOptions = assignees.asData?.value;
    if (latestOptions != null) _lastOptions = latestOptions;
    return AlertDialog(
      title: Text(strings.newAssignment),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<AssetAssignee>(
                displayStringForOption: (agent) => agent.displayName,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return _lastOptions;
                  return _lastOptions.where(
                    (agent) =>
                        agent.displayName.toLowerCase().contains(query) ||
                        agent.email.toLowerCase().contains(query),
                  );
                },
                onSelected: (agent) => setState(() => _assignee = agent),
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onFieldSubmitted,
                ) =>
                    TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: strings.searchAgents,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: assignees.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _queueSearch,
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  validator: (_) =>
                      _assignee == null ? strings.requiredField : null,
                ),
              ),
              if (assignees.hasError) ...[
                const SizedBox(height: 10),
                _MessageBox(
                  message: _errorMessage(context, assignees.error!),
                  isError: true,
                ),
              ] else if (!assignees.isLoading && _lastOptions.isEmpty) ...[
                const SizedBox(height: 10),
                Text(strings.noActiveAgents),
              ],
              const SizedBox(height: 14),
              CommonTextInput(
                label: strings.assignmentDate,
                controller: _date,
                readOnly: true,
                enabled: !_submitting,
                suffixIcon: const Icon(Icons.calendar_month_outlined),
                onTap: _pickDate,
                validator: (value) => _required(context, value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _MessageBox(message: _error!, isError: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(strings.assignAsset),
        ),
      ],
    );
  }
}

class _AssetStateDialog extends StatefulWidget {
  const _AssetStateDialog({
    required this.states,
    required this.currentStateName,
    required this.onSubmit,
  });

  final List<AssetParameter> states;
  final String currentStateName;
  final Future<void> Function(AssetParameter state, String observation)
      onSubmit;

  @override
  State<_AssetStateDialog> createState() => _AssetStateDialogState();
}

class _AssetStateDialogState extends State<_AssetStateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observation = TextEditingController();
  AssetParameter? _selected;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final state in widget.states) {
      if (state.name == widget.currentStateName) {
        _selected = state;
        break;
      }
    }
  }

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (_submitting || selected == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(selected, _observation.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AlertDialog(
      title: Text(strings.changeAssetState),
      content: SizedBox(
        width: math.min(520, MediaQuery.sizeOf(context).width - 48),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AssetParameter>(
                value: _selected,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: strings.selectAssetState),
                items: widget.states
                    .map(
                      (state) => DropdownMenuItem(
                        value: state,
                        child: Text(state.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _selected = value),
              ),
              const SizedBox(height: 12),
              CommonTextInput(
                label: strings.stateChangeObservation,
                controller: _observation,
                isMultiline: true,
                enabled: !_submitting,
                validator: (value) => _required(context, value),
              ),
              if (widget.states.isEmpty) ...[
                const SizedBox(height: 10),
                Text(strings.configureAssetParametersFirst),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _MessageBox(message: _error!, isError: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _submitting || _selected == null ? null : _submit,
          child: Text(strings.save),
        ),
      ],
    );
  }
}

class _AssetDecommissionDialog extends StatefulWidget {
  const _AssetDecommissionDialog({required this.onSubmit});

  final Future<void> Function(String observation) onSubmit;

  @override
  State<_AssetDecommissionDialog> createState() =>
      _AssetDecommissionDialogState();
}

class _AssetDecommissionDialogState extends State<_AssetDecommissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observation = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_observation.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AlertDialog(
      title: Text(strings.decommissionAsset),
      content: SizedBox(
        width: math.min(560, MediaQuery.sizeOf(context).width - 48),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.decommissionAssetConfirmation),
              const SizedBox(height: 12),
              CommonTextInput(
                label: strings.decommissionObservation,
                controller: _observation,
                isMultiline: true,
                enabled: !_submitting,
                validator: (value) => _required(context, value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _MessageBox(message: _error!, isError: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_2_outlined),
          label: Text(strings.decommissionAsset),
        ),
      ],
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 2 : 1;
          const spacing = 14.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? colors.onErrorContainer : colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

Future<void> _registerAsset(
  WidgetRef ref,
  Map<String, Object?> fields,
) =>
    _manageConfiguration(
      ref,
      recordType: 'asset',
      operation: 'register',
      recordId: fields['assetId']!.toString(),
      fields: fields,
    );

Future<void> _operateAsset(
  WidgetRef ref,
  String assetId,
  String operation,
  Map<String, Object?> fields,
) async {
  final session = await ref.read(itsmSessionProvider.future);
  if (session == null) {
    throw const AssetsConfigurationAccessDenied(
      'An authenticated ITSM session is required.',
    );
  }
  final controller =
      await ref.read(assetsConfigurationCommandControllerProvider.future);
  final nonce = DateTime.now().toUtc().microsecondsSinceEpoch;
  await controller.operateAsset(
    AssetOperationalCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'asset-$operation-$assetId-$nonce',
        correlationId: 'asset-$assetId-$nonce',
        actorUserId: session.userId,
        actorRole: session.role,
        actorDisplayName: session.displayName,
      ),
      assetId: assetId,
      operation: operation,
      fields: fields,
    ),
  );
}

Future<void> _manageConfiguration(
  WidgetRef ref, {
  required String recordType,
  required String operation,
  required String recordId,
  required Map<String, Object?> fields,
}) async {
  final session = await ref.read(itsmSessionProvider.future);
  if (session == null) {
    throw const AssetsConfigurationAccessDenied(
      'An authenticated ITSM session is required.',
    );
  }
  final controller =
      await ref.read(assetsConfigurationCommandControllerProvider.future);
  final nonce = DateTime.now().toUtc().microsecondsSinceEpoch;
  await controller.manageConfiguration(
    ManagerConfigurationCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'asset-configuration-$recordId-$nonce',
        correlationId: 'asset-configuration-$nonce',
        actorUserId: session.userId,
        actorRole: session.role,
        actorDisplayName: session.displayName,
      ),
      recordType: recordType,
      operation: operation,
      recordId: recordId,
      fields: fields,
    ),
  );
}

String? _required(BuildContext context, String? value) =>
    (value?.trim().isEmpty ?? true)
        ? AssetsConfigurationStrings.of(context).positiveQuantityError
        : null;

String _isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _slug(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'value' : normalized;
}

double _dialogWidth(BuildContext context) =>
    math.max(280, math.min(820, MediaQuery.sizeOf(context).width - 48));

IconData _parameterIcon(AssetParameterType type) => switch (type) {
      AssetParameterType.category => Icons.category_outlined,
      AssetParameterType.location => Icons.location_on_outlined,
      AssetParameterType.state => Icons.fact_check_outlined,
    };

String _errorMessage(BuildContext context, Object error) =>
    assetsConfigurationErrorMessage(
      error,
      AssetsConfigurationStrings.of(context),
    );

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_errorMessage(context, error))),
  );
}
