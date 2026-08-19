import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/custom_filledbutton.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

Future<UserManagementModule?> showModuleFormSheet(
  BuildContext context, {
  required Future<void> Function(UserManagementModule module) onSubmit,
  List<UserManagementModule> existingModules = const [],
  UserManagementModule? module,
  String Function(Object error)? submissionErrorBuilder,
  void Function(Object error, StackTrace stackTrace)? onSubmissionError,
}) {
  return showModalBottomSheet<UserManagementModule>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => ModuleFormSheet(
      existingModules: existingModules,
      module: module,
      onSubmit: onSubmit,
      submissionErrorBuilder: submissionErrorBuilder,
      onSubmissionError: onSubmissionError,
    ),
  );
}

class ModuleFormSheet extends StatefulWidget {
  const ModuleFormSheet({
    required this.onSubmit,
    this.existingModules = const [],
    this.module,
    this.submissionErrorBuilder,
    this.onSubmissionError,
    super.key,
  });

  final List<UserManagementModule> existingModules;
  final UserManagementModule? module;
  final Future<void> Function(UserManagementModule module) onSubmit;
  final String Function(Object error)? submissionErrorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onSubmissionError;

  @override
  State<ModuleFormSheet> createState() => _ModuleFormSheetState();
}

class _ModuleFormSheetState extends State<ModuleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  late Set<String> _selectedRoleValues;
  String? _selectedKey;
  bool _isSubmitting = false;
  String? _submissionError;

  bool get _isEditing => widget.module != null;

  List<String> get _availableDefaultKeys {
    final existingKeys = widget.existingModules
        .map((module) => module.key.trim().toLowerCase())
        .toSet();
    return Modules.all
        .map((module) => module.key)
        .where((key) => !existingKeys.contains(key))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final module = widget.module;
    _nameController = TextEditingController(text: module?.name ?? '');
    _descriptionController =
        TextEditingController(text: module?.description ?? '');
    _isActive = module?.isActive ?? true;
    _selectedRoleValues = (module?.accessRoles ?? const <ModuleAccessRole>[])
        .where((role) => role != ModuleAccessRole.none)
        .map((role) => role.value)
        .toSet();
    if (module != null) {
      _selectedKey = module.key;
    } else {
      final availableKeys = _availableDefaultKeys;
      if (availableKeys.isNotEmpty) _applyDefinition(availableKeys.first);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final availableKeys = _availableDefaultKeys;
    final noKeyAvailable = !_isEditing && availableKeys.isEmpty;
    return PopScope(
      canPop: !_isSubmitting,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lookup(_isEditing ? 'umEditModule' : 'umAddModule'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                if (noKeyAvailable)
                  EmptyStateView(
                    icon: Icons.info_outline,
                    title: l10n.lookup('umNoModuleKeyAvailable'),
                    description:
                        l10n.lookup('umNoModuleKeyAvailableDescription'),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    key: const Key('module-key-field'),
                    value: _selectedKey,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.lookup('umModuleKey'),
                    ),
                    items: (_isEditing ? [_selectedKey!] : availableKeys)
                        .map(
                          (key) => DropdownMenuItem<String>(
                            value: key,
                            child: Text(key),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _isEditing || _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _applyDefinition(value));
                          },
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: l10n.lookup('umModuleName'),
                    type: CommonTextInputType.name,
                    controller: _nameController,
                    enabled: !_isSubmitting,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.lookup('umRequiredField')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: l10n.lookup('umModuleDescription'),
                    controller: _descriptionController,
                    enabled: !_isSubmitting,
                    isMultiline: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.lookup('umAvailableRoles'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ModuleAccessRole.values
                        .where((role) => role != ModuleAccessRole.none)
                        .map(
                          (role) => FilterChip(
                            label: Text(role.label),
                            selected: _selectedRoleValues.contains(role.value),
                            onSelected: _isSubmitting
                                ? null
                                : (selected) => setState(() {
                                      if (selected) {
                                        _selectedRoleValues.add(role.value);
                                      } else {
                                        _selectedRoleValues.remove(role.value);
                                      }
                                    }),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    title: Text(l10n.lookup('umActive')),
                    contentPadding: EdgeInsets.zero,
                    onChanged: _isSubmitting
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                  if (_submissionError != null) ...[
                    const SizedBox(height: 12),
                    _ModuleSubmissionError(message: _submissionError!),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomFilledButton(
                          key: const Key('module-form-submit'),
                          text: _isEditing ? l10n.save : l10n.create,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(l10n.cancel),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final key = _selectedKey?.trim().toLowerCase() ?? '';
    if (key.isEmpty) return;
    final existing = widget.module;
    final module = UserManagementModule(
      id: existing?.id ?? '',
      key: key,
      name: _nameController.text.trim(),
      nameLower: _nameController.text.trim().toLowerCase(),
      description: _descriptionController.text.trim(),
      availableRoles: _selectedRoleValues.toList(growable: false),
      isActive: _isActive,
      createdAt: existing?.createdAt,
      updatedAt: _isEditing ? DateTime.now() : null,
    );
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      await widget.onSubmit(module);
      if (mounted) Navigator.of(context).pop(module);
    } catch (error, stackTrace) {
      widget.onSubmissionError?.call(error, stackTrace);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError =
            widget.submissionErrorBuilder?.call(error) ?? error.toString();
      });
    }
  }

  void _applyDefinition(String key) {
    _selectedKey = key;
    ModuleDefinition? definition;
    for (final candidate in Modules.all) {
      if (candidate.key == key) {
        definition = candidate;
        break;
      }
    }
    if (definition == null) return;
    _nameController.text = definition.name;
    _selectedRoleValues
      ..clear()
      ..addAll(
        definition.availableRoles
            .where((role) => role != ModuleAccessRole.none)
            .map((role) => role.value),
      );
  }
}

class _ModuleSubmissionError extends StatelessWidget {
  const _ModuleSubmissionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('module-form-submission-error'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
