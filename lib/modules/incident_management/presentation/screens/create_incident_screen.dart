import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateIncidentScreen extends ConsumerStatefulWidget {
  const CreateIncidentScreen({super.key});

  @override
  ConsumerState<CreateIncidentScreen> createState() =>
      _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends ConsumerState<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _assetIdController = TextEditingController();
  final _impactDescriptionController = TextEditingController();

  String _affectedServiceId = '';
  String _categoryId = '';
  String _subcategoryName = '';
  String _impact = '';
  String _urgency = '';
  IncidentUser? _selectedAffectedAgent;
  bool _isBlocking = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _deviceTypeController.dispose();
    _assetIdController.dispose();
    _impactDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(itServicesProvider);
    final categoriesAsync = ref.watch(incidentCategoriesProvider);
    final agentsAsync = ref.watch(incidentAgentsProvider);
    final userAsync = ref.watch(currentIncidentUserProvider);
    final actorAsync = ref.watch(currentIncidentActorProvider);
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 980,
        child: userAsync.when(
          data: (user) {
            final actor = actorAsync.valueOrNull;
            final canCreate = user.role == IncidentRole.user ||
                user.role == IncidentRole.manager;
            if (!canCreate) {
              return ErrorStateView(
                title: l10n.readOnlyIncidentAccess,
                description: l10n.onlyUsersAndManagersCreateIncidents,
              );
            }

            final isManager = user.role == IncidentRole.manager;
            final services = servicesAsync.valueOrNull ?? const <ItService>[];
            final categories =
                categoriesAsync.valueOrNull ?? const <IncidentCategory>[];
            final selectedCategory = categories.firstWhereOrNull(
              (category) => category.id == _categoryId,
            );

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: PageHeader(
                            title: isManager
                                ? l10n.newSupportIncident
                                : l10n.submitSupportTicket,
                            description: isManager
                                ? l10n.createIncidentManagerDescription
                                : l10n.createIncidentUserDescription,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CommonTextInput(
                              label: l10n.title,
                              hintText: l10n.titleExampleEmailAccess,
                              type: CommonTextInputType.text,
                              controller: _titleController,
                              validator: _required(l10n.enterTitle),
                            ),
                            const SizedBox(height: 12),
                            CommonTextInput(
                              label: l10n.shortDescription,
                              hintText: l10n.describeIssueAndWork,
                              type: CommonTextInputType.text,
                              isMultiline: true,
                              controller: _descriptionController,
                              maxLines: 4,
                              validator: _required(l10n.enterShortDescription),
                            ),
                            const SizedBox(height: 12),
                            servicesAsync.when(
                              data: (_) => _ServiceDropdown(
                                services: services,
                                value: _affectedServiceId,
                                onChanged: (value) {
                                  setState(() {
                                    _affectedServiceId = value ?? '';
                                  });
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (error, _) => Text(
                                '${l10n.unableToLoad}: $error',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _isBlocking,
                              title: Text(l10n.thisIssueBlocksMyWork),
                              subtitle: Text(l10n.blockingWorkDescription),
                              onChanged: (value) {
                                setState(() {
                                  _isBlocking = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isManager) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.managerCategorization,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.managerCategorizationDescription,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              agentsAsync.when(
                                data: (agents) => _AgentSearchField(
                                  agents: agents,
                                  selectedAgent: _selectedAffectedAgent,
                                  onSelected: (agent) {
                                    setState(() {
                                      _selectedAffectedAgent = agent;
                                    });
                                  },
                                  onCleared: () {
                                    setState(() {
                                      _selectedAffectedAgent = null;
                                    });
                                  },
                                ),
                                loading: () => const LinearProgressIndicator(),
                                error: (error, _) => Text(
                                  '${l10n.unableToLoad}: $error',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ResponsiveFields(
                                children: [
                                  CommonTextInput(
                                    label: l10n.location,
                                    hintText: l10n.locationHint,
                                    type: CommonTextInputType.text,
                                    controller: _locationController,
                                  ),
                                  CommonTextInput(
                                    label: l10n.deviceType,
                                    hintText: l10n.deviceTypeHint,
                                    type: CommonTextInputType.text,
                                    controller: _deviceTypeController,
                                  ),
                                  CommonTextInput(
                                    label: l10n.assetId,
                                    hintText: l10n.assetIdHint,
                                    type: CommonTextInputType.text,
                                    controller: _assetIdController,
                                  ),
                                  _CategoryDropdown(
                                    categories: categories,
                                    value: _categoryId,
                                    onChanged: (value) {
                                      setState(() {
                                        _categoryId = value ?? '';
                                        _subcategoryName = '';
                                      });
                                    },
                                  ),
                                  _SubcategoryDropdown(
                                    subcategories:
                                        selectedCategory?.subcategories ??
                                            const [],
                                    value: _subcategoryName,
                                    onChanged: (value) {
                                      setState(() {
                                        _subcategoryName = value ?? '';
                                      });
                                    },
                                  ),
                                  _EnumDropdown(
                                    label: l10n.impact,
                                    requiredMessage: l10n.selectImpact,
                                    value: _impact,
                                    values: IncidentImpact.values
                                        .map(
                                          (item) => _Option(
                                            item.value,
                                            localizedIncidentImpactLabel(
                                              l10n,
                                              item,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => _impact = value ?? '');
                                    },
                                  ),
                                  _EnumDropdown(
                                    label: l10n.urgency,
                                    requiredMessage: l10n.selectUrgency,
                                    value: _urgency,
                                    values: IncidentUrgency.values
                                        .map(
                                          (item) => _Option(
                                            item.value,
                                            localizedIncidentUrgencyLabel(
                                              l10n,
                                              item,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => _urgency = value ?? '');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CommonTextInput(
                                label: l10n.impactDescription,
                                hintText: l10n.impactDescriptionHint,
                                type: CommonTextInputType.text,
                                isMultiline: true,
                                controller: _impactDescriptionController,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSaving || actor == null
                            ? null
                            : () => _save(user),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _isSaving ? l10n.submitting : l10n.submitTicket,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => LoadingStateView(message: l10n.loadingProfile),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadProfile,
            description: error.toString(),
            onRetry: () => ref.invalidate(currentIncidentUserProvider),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  Future<void> _save(IncidentUser user) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty) {
      return;
    }

    final services =
        ref.read(itServicesProvider).valueOrNull ?? const <ItService>[];
    final selectedService = services.firstWhereOrNull(
      (service) => service.id == _affectedServiceId,
    );
    if (selectedService == null) {
      _showMessage(S.of(context).selectAffectedService);
      return;
    }

    final isManager = user.role == IncidentRole.manager;
    final affectedUser = isManager ? _selectedAffectedAgent ?? user : user;
    final categories = ref.read(incidentCategoriesProvider).valueOrNull ??
        const <IncidentCategory>[];
    final selectedCategory = categories.firstWhereOrNull(
      (category) => category.id == _categoryId,
    );

    if (isManager &&
        (selectedCategory == null || _impact.isEmpty || _urgency.isEmpty)) {
      _showMessage(S.of(context).completeCategoryImpactUrgency);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final priority = isManager
        ? calculateIncidentPriority(impact: _impact, urgency: _urgency).value
        : IncidentPriority.none.value;

    final ticket = IncidentTicket.empty().copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: isManager
          ? IncidentStatus.inProgress.value
          : IncidentStatus.open.value,
      createdByUserId: user.id,
      createdByName: user.displayName,
      createdByEmail: user.email,
      createdByDepartmentId: user.departmentId,
      createdByDepartmentName: user.departmentName,
      createdByServiceId: user.serviceId,
      createdByServiceName: user.serviceName,
      affectedUserId: affectedUser.id,
      affectedUserName: affectedUser.displayName,
      affectedUserEmail: affectedUser.email,
      affectedServiceId: selectedService.id,
      affectedServiceName: selectedService.name,
      location: isManager ? _locationController.text.trim() : '',
      deviceType: isManager ? _deviceTypeController.text.trim() : '',
      assetId: isManager ? _assetIdController.text.trim() : '',
      userImpactDescription:
          isManager ? _impactDescriptionController.text.trim() : '',
      isBlocking: _isBlocking,
      categoryId: isManager ? selectedCategory?.id ?? '' : '',
      categoryName: isManager ? selectedCategory?.name ?? '' : '',
      subcategoryId: isManager ? _subcategoryName : '',
      subcategoryName: isManager ? _subcategoryName : '',
      impact: isManager ? _impact : '',
      urgency: isManager ? _urgency : '',
      priority: priority,
    );

    try {
      await ref.read(incidentRepositoryProvider).createTicket(ticket, actor);
      if (mounted) {
        context.go('/service/incidents');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AgentSearchField extends StatefulWidget {
  const _AgentSearchField({
    required this.agents,
    required this.selectedAgent,
    required this.onSelected,
    required this.onCleared,
  });

  final List<IncidentUser> agents;
  final IncidentUser? selectedAgent;
  final ValueChanged<IncidentUser> onSelected;
  final VoidCallback onCleared;

  @override
  State<_AgentSearchField> createState() => _AgentSearchFieldState();
}

class _AgentSearchFieldState extends State<_AgentSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedAgent == null
          ? ''
          : _agentLabel(widget.selectedAgent!),
    );
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AgentSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAgent?.id != oldWidget.selectedAgent?.id) {
      _controller.text = widget.selectedAgent == null
          ? ''
          : _agentLabel(widget.selectedAgent!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return RawAutocomplete<IncidentUser>(
      displayStringForOption: _agentLabel,
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return widget.agents.take(12);
        }
        return widget.agents.where((agent) {
          final haystack = [
            agent.displayName,
            agent.email,
            agent.matricule,
            agent.departmentName,
            agent.serviceName,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        }).take(12);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        return CommonTextInput(
          label: l10n.affectedAgent,
          type: CommonTextInputType.name,
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: l10n.searchAffectedAgentHint,
            prefixIcon: const Icon(Icons.person_search_outlined),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            final selected = widget.selectedAgent;
            if (selected != null && value != _agentLabel(selected)) {
              widget.onCleared();
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final agent = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(agent.displayName),
                    subtitle: Text(
                      [
                        agent.email,
                        agent.matricule,
                      ].where((value) => value.isNotEmpty).join(' - '),
                    ),
                    onTap: () => onSelected(agent),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  static String _agentLabel(IncidentUser agent) {
    final suffix = agent.email.isEmpty ? '' : ' (${agent.email})';
    return '${agent.displayName}$suffix';
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 720;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) {
            return SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ServiceDropdown extends StatelessWidget {
  const _ServiceDropdown({
    required this.services,
    required this.value,
    required this.onChanged,
  });

  final List<ItService> services;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final effectiveValue =
        services.any((service) => service.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.affectedItService,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return l10n.selectAffectedService;
        }
        return null;
      },
      items: services
          .map(
            (service) => DropdownMenuItem(
              value: service.id,
              child: Text(service.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<IncidentCategory> categories;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final effectiveValue =
        categories.any((category) => category.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.category,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return l10n.selectCategory;
        }
        return null;
      },
      items: categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SubcategoryDropdown extends StatelessWidget {
  const _SubcategoryDropdown({
    required this.subcategories,
    required this.value,
    required this.onChanged,
  });

  final List<String> subcategories;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final effectiveValue = subcategories.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.subcategory,
        border: const OutlineInputBorder(),
      ),
      items: subcategories
          .map(
            (subcategory) => DropdownMenuItem(
              value: subcategory,
              child: Text(subcategory),
            ),
          )
          .toList(),
      onChanged: subcategories.isEmpty ? null : onChanged,
    );
  }
}

class _EnumDropdown extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.requiredMessage,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String requiredMessage;
  final String value;
  final List<_Option> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        values.any((option) => option.value == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return requiredMessage;
        }
        return null;
      },
      items: values
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _Option {
  const _Option(this.value, this.label);

  final String value;
  final String label;
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
