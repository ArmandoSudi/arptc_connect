import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_category.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:arptc_connect/modules/incident_management/domain/it_service.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_priority_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_status_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_timeline.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class ManagerIncidentDetailsScreen extends ConsumerStatefulWidget {
  const ManagerIncidentDetailsScreen({
    required this.ticketId,
    super.key,
  });

  final String ticketId;

  @override
  ConsumerState<ManagerIncidentDetailsScreen> createState() =>
      _ManagerIncidentDetailsScreenState();
}

class _ManagerIncidentDetailsScreenState
    extends ConsumerState<ManagerIncidentDetailsScreen> {
  final _locationController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _assetIdController = TextEditingController();
  final _resolutionSummaryController = TextEditingController();
  final _resolutionCodeController = TextEditingController();
  final _internalNoteController = TextEditingController();

  String _loadedTicketId = '';
  String _affectedServiceId = '';
  String _categoryId = '';
  String _subcategoryName = '';
  String _impact = '';
  String _urgency = '';
  String _assignedToUserId = '';
  bool _isCategorizing = false;
  bool _isAssigning = false;
  bool _isResolving = false;
  bool _isClosing = false;
  bool _isCancelling = false;
  bool _isAddingNote = false;

  @override
  void dispose() {
    _locationController.dispose();
    _deviceTypeController.dispose();
    _assetIdController.dispose();
    _resolutionSummaryController.dispose();
    _resolutionCodeController.dispose();
    _internalNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(incidentTicketProvider(widget.ticketId));
    final categories = ref.watch(incidentCategoriesProvider).valueOrNull ?? [];
    final services = ref.watch(itServicesProvider).valueOrNull ?? [];
    final staff = ref.watch(itStaffUsersProvider).valueOrNull ?? [];
    final currentUser = ref.watch(currentIncidentUserProvider).valueOrNull;
    final comments = ref.watch(incidentCommentsProvider(widget.ticketId));
    final logs = ref.watch(incidentAuditLogsProvider(widget.ticketId));
    final l10n = S.of(context);

    return Scaffold(
      body: ContentView(
        maxWidth: 1120,
        child: ticketAsync.when(
          data: (ticket) {
            if (ticket == null) {
              return EmptyStateView(
                icon: Icons.confirmation_number_outlined,
                title: l10n.incidentNotFound,
              );
            }
            _hydrateFromTicket(ticket);

            final selectedCategory = categories.firstWhereOrNull(
              (category) => category.id == _categoryId,
            );
            final assignableUsers = _assignableUsers(staff, currentUser);

            return SingleChildScrollView(
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
                          title: ticket.ticketNumber,
                          description: ticket.title,
                        ),
                      ),
                      IncidentStatusBadge(status: ticket.status),
                      const SizedBox(width: 8),
                      IncidentPriorityBadge(priority: ticket.priority),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RequesterSummary(ticket: ticket),
                  const SizedBox(height: 16),
                  _WorkflowStepper(
                    ticket: ticket,
                    services: services,
                    affectedServiceId: _affectedServiceId,
                    onAffectedServiceChanged: (value) {
                      setState(() {
                        _affectedServiceId = value ?? '';
                      });
                    },
                    locationController: _locationController,
                    deviceTypeController: _deviceTypeController,
                    assetIdController: _assetIdController,
                    categories: categories,
                    selectedCategory: selectedCategory,
                    categoryId: _categoryId,
                    onCategoryChanged: (value) {
                      setState(() {
                        _categoryId = value ?? '';
                        _subcategoryName = '';
                      });
                    },
                    subcategoryName: _subcategoryName,
                    onSubcategoryChanged: (value) {
                      setState(() {
                        _subcategoryName = value ?? '';
                      });
                    },
                    impact: _impact,
                    onImpactChanged: (value) {
                      setState(() => _impact = value ?? '');
                    },
                    urgency: _urgency,
                    onUrgencyChanged: (value) {
                      setState(() => _urgency = value ?? '');
                    },
                    assignableUsers: assignableUsers,
                    assignedToUserId: _assignedToUserId,
                    onAssignedToChanged: (value) {
                      setState(() {
                        _assignedToUserId = value ?? '';
                      });
                    },
                    resolutionSummaryController: _resolutionSummaryController,
                    resolutionCodeController: _resolutionCodeController,
                    isCategorizing: _isCategorizing,
                    isAssigning: _isAssigning,
                    isResolving: _isResolving,
                    isClosing: _isClosing,
                    isCancelling: _isCancelling,
                    onCategorize: () =>
                        _categorizeTicket(ticket, categories, services),
                    onCancel: () => _confirmCancelTicket(ticket),
                    onAssign: () => _assignTicket(ticket, assignableUsers),
                    onResolve: () => _markResolved(ticket),
                    onClose: () => _closeTicket(ticket),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.internalNotes,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          CommonTextInput(
                            label: l10n.addNote,
                            hintText: l10n.addInternalNoteHint,
                            type: CommonTextInputType.text,
                            isMultiline: true,
                            controller: _internalNoteController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _isAddingNote ? null : _addNote,
                              icon: const Icon(Icons.note_add_outlined),
                              label: Text(
                                _isAddingNote ? l10n.adding : l10n.addNote,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.timeline,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          IncidentTimeline(
                            comments: comments.valueOrNull ?? const [],
                            auditLogs: logs.valueOrNull ?? const [],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => LoadingStateView(message: l10n.loadingIncident),
          error: (error, _) => ErrorStateView(
            title: l10n.unableToLoadIncident,
            description: error.toString(),
            onRetry: () =>
                ref.invalidate(incidentTicketProvider(widget.ticketId)),
          ),
        ),
      ),
    );
  }

  void _hydrateFromTicket(IncidentTicket ticket) {
    if (_loadedTicketId == ticket.id) {
      return;
    }
    _loadedTicketId = ticket.id;
    _affectedServiceId = ticket.affectedServiceId;
    _categoryId = ticket.categoryId;
    _subcategoryName = ticket.subcategoryName;
    _impact = ticket.impact;
    _urgency = ticket.urgency;
    _assignedToUserId = ticket.assignedToUserId;
    _locationController.text = ticket.location;
    _deviceTypeController.text = ticket.deviceType;
    _assetIdController.text = ticket.assetId;
    _resolutionSummaryController.text = ticket.resolutionSummary;
    _resolutionCodeController.text = ticket.resolutionCode;
  }

  Future<void> _categorizeTicket(
    IncidentTicket ticket,
    List<IncidentCategory> categories,
    List<ItService> services,
  ) async {
    final l10n = S.of(context);
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }

    final service = services.firstWhereOrNull(
      (item) => item.id == _affectedServiceId,
    );
    final category = categories.firstWhereOrNull(
      (item) => item.id == _categoryId,
    );
    if (service == null ||
        category == null ||
        _impact.trim().isEmpty ||
        _urgency.trim().isEmpty) {
      _showMessage(l10n.selectServiceCategoryImpactUrgency);
      return;
    }

    setState(() => _isCategorizing = true);
    try {
      await ref.read(incidentRepositoryProvider).updateManagerFields(
        ticketId: ticket.id,
        actor: actor,
        fields: {
          'affectedServiceId': service.id,
          'affectedServiceName': service.name,
          'location': _locationController.text.trim(),
          'deviceType': _deviceTypeController.text.trim(),
          'assetId': _assetIdController.text.trim(),
          'categoryId': category.id,
          'categoryName': category.name,
          'subcategoryId': _subcategoryName,
          'subcategoryName': _subcategoryName,
          'impact': _impact,
          'urgency': _urgency,
          'status': IncidentStatus.inProgress.value,
          'lifecycleState': IncidentLifecycleState.active.value,
        },
      );
      _showMessage(l10n.ticketCategorized);
    } finally {
      if (mounted) {
        setState(() => _isCategorizing = false);
      }
    }
  }

  Future<void> _confirmCancelTicket(IncidentTicket ticket) async {
    final l10n = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = S.of(context);
        return AlertDialog(
          title: Text(l10n.cancelThisTicket),
          content: Text(l10n.cancelTicketWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.keepTicket),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.cancelTicket),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }

    setState(() => _isCancelling = true);
    try {
      await ref.read(incidentRepositoryProvider).cancelTicket(
            ticketId: ticket.id,
            actor: actor,
          );
      _showMessage(l10n.ticketCancelled);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _assignTicket(
    IncidentTicket ticket,
    List<IncidentUser> users,
  ) async {
    final l10n = S.of(context);
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }
    final assignedUser = users.firstWhereOrNull(
      (user) => user.id == _assignedToUserId,
    );
    if (assignedUser == null) {
      _showMessage(l10n.selectItStaffAssignee);
      return;
    }

    setState(() => _isAssigning = true);
    try {
      await ref.read(incidentRepositoryProvider).updateManagerFields(
        ticketId: ticket.id,
        actor: actor,
        fields: {
          'assignedToUserId': assignedUser.id,
          'assignedToName': assignedUser.displayName,
          'assignedToEmail': assignedUser.email,
        },
      );
      _showMessage(l10n.ticketAssigned);
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Future<void> _markResolved(IncidentTicket ticket) async {
    final l10n = S.of(context);
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }
    final summary = _resolutionSummaryController.text.trim();
    if (summary.isEmpty) {
      _showMessage(l10n.enterResolutionSummaryBeforeSolved);
      return;
    }

    setState(() => _isResolving = true);
    try {
      await ref.read(incidentRepositoryProvider).markTicketResolved(
            ticketId: ticket.id,
            resolutionSummary: summary,
            resolutionCode: _resolutionCodeController.text.trim(),
            actor: actor,
          );
      _showMessage(l10n.ticketMarkedSolved);
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  Future<void> _closeTicket(IncidentTicket ticket) async {
    final l10n = S.of(context);
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (actor == null) {
      return;
    }
    final summary = _resolutionSummaryController.text.trim();
    if (summary.isEmpty) {
      _showMessage(l10n.enterResolutionSummaryBeforeClosing);
      return;
    }

    setState(() => _isClosing = true);
    try {
      await ref.read(incidentRepositoryProvider).closeTicket(
            ticketId: ticket.id,
            resolutionSummary: summary,
            resolutionCode: _resolutionCodeController.text.trim(),
            actor: actor,
          );
      _showMessage(l10n.ticketClosed);
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  Future<void> _addNote() async {
    final l10n = S.of(context);
    final body = _internalNoteController.text.trim();
    final actor = ref.read(currentIncidentActorProvider).valueOrNull;
    if (body.isEmpty || actor == null) {
      return;
    }
    setState(() => _isAddingNote = true);
    try {
      await ref.read(incidentRepositoryProvider).addInternalNote(
            ticketId: widget.ticketId,
            body: body,
            actor: actor,
          );
      _internalNoteController.clear();
      _showMessage(l10n.internalNoteAdded);
    } finally {
      if (mounted) {
        setState(() => _isAddingNote = false);
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

  List<IncidentUser> _assignableUsers(
    List<IncidentUser> staff,
    IncidentUser? currentUser,
  ) {
    final byId = <String, IncidentUser>{
      for (final user in staff) user.id: user,
    };
    if (currentUser != null && currentUser.id.isNotEmpty) {
      byId[currentUser.id] = currentUser;
    }
    return byId.values.toList()
      ..sort(
        (left, right) => left.displayName
            .toLowerCase()
            .compareTo(right.displayName.toLowerCase()),
      );
  }
}

class _WorkflowStepper extends StatelessWidget {
  const _WorkflowStepper({
    required this.ticket,
    required this.services,
    required this.affectedServiceId,
    required this.onAffectedServiceChanged,
    required this.locationController,
    required this.deviceTypeController,
    required this.assetIdController,
    required this.categories,
    required this.selectedCategory,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.subcategoryName,
    required this.onSubcategoryChanged,
    required this.impact,
    required this.onImpactChanged,
    required this.urgency,
    required this.onUrgencyChanged,
    required this.assignableUsers,
    required this.assignedToUserId,
    required this.onAssignedToChanged,
    required this.resolutionSummaryController,
    required this.resolutionCodeController,
    required this.isCategorizing,
    required this.isAssigning,
    required this.isResolving,
    required this.isClosing,
    required this.isCancelling,
    required this.onCategorize,
    required this.onCancel,
    required this.onAssign,
    required this.onResolve,
    required this.onClose,
  });

  final IncidentTicket ticket;
  final List<ItService> services;
  final String affectedServiceId;
  final ValueChanged<String?> onAffectedServiceChanged;
  final TextEditingController locationController;
  final TextEditingController deviceTypeController;
  final TextEditingController assetIdController;
  final List<IncidentCategory> categories;
  final IncidentCategory? selectedCategory;
  final String categoryId;
  final ValueChanged<String?> onCategoryChanged;
  final String subcategoryName;
  final ValueChanged<String?> onSubcategoryChanged;
  final String impact;
  final ValueChanged<String?> onImpactChanged;
  final String urgency;
  final ValueChanged<String?> onUrgencyChanged;
  final List<IncidentUser> assignableUsers;
  final String assignedToUserId;
  final ValueChanged<String?> onAssignedToChanged;
  final TextEditingController resolutionSummaryController;
  final TextEditingController resolutionCodeController;
  final bool isCategorizing;
  final bool isAssigning;
  final bool isResolving;
  final bool isClosing;
  final bool isCancelling;
  final VoidCallback onCategorize;
  final VoidCallback onCancel;
  final VoidCallback onAssign;
  final VoidCallback onResolve;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final currentStep = _currentStep(ticket);
    final isActive =
        ticket.lifecycleState == IncidentLifecycleState.active.value;
    final isOpen = ticket.status == IncidentStatus.open.value;
    final isResolved = ticket.status == IncidentStatus.resolved.value;
    final isClosed = ticket.status == IncidentStatus.closed.value;
    final isCancelled = ticket.status == IncidentStatus.cancelled.value;
    final canCategorize = isActive && !isResolved && !isCancelled;
    final canCancel = isActive &&
        !isResolved &&
        !isCancelled &&
        ticket.assignedToUserId.trim().isEmpty;
    final canAssign = isActive && !isOpen && !isResolved && !isCancelled;
    final canResolve = isActive &&
        !isOpen &&
        !isResolved &&
        !isCancelled &&
        ticket.assignedToUserId.trim().isNotEmpty;
    final canClose = isActive && isResolved;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Stepper(
          type: StepperType.vertical,
          physics: const NeverScrollableScrollPhysics(),
          currentStep: currentStep,
          controlsBuilder: (_, __) => const SizedBox.shrink(),
          steps: [
            Step(
              title: Text(l10n.workflowStepSubmitTicket),
              subtitle: Text(l10n.workflowStepSubmitTicketDescription),
              isActive: currentStep >= 0,
              state: StepState.complete,
              content: _SubmittedStep(ticket: ticket),
            ),
            Step(
              title: Text(l10n.workflowStepCategorizeTicket),
              subtitle: Text(
                isOpen
                    ? l10n.workflowStepCategorizeOpenDescription
                    : l10n.workflowStepCategorizeActiveDescription,
              ),
              isActive: currentStep >= 1,
              state: _categorizationStepState(ticket),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap(8),
                  _ResponsiveFields(
                    children: [
                      _ServiceDropdown(
                        services: services,
                        value: affectedServiceId,
                        onChanged:
                            canCategorize ? onAffectedServiceChanged : null,
                      ),
                      CommonTextInput(
                        label: l10n.deviceType,
                        hintText: l10n.deviceTypeHint,
                        type: CommonTextInputType.text,
                        controller: deviceTypeController,
                        enabled: canCategorize,
                      ),
                      CommonTextInput(
                        label: l10n.location,
                        hintText: l10n.locationHint,
                        type: CommonTextInputType.text,
                        controller: locationController,
                        enabled: canCategorize,
                      ),
                      CommonTextInput(
                        label: l10n.assetId,
                        hintText: l10n.assetIdHint,
                        type: CommonTextInputType.text,
                        controller: assetIdController,
                        enabled: canCategorize,
                      ),
                      _CategoryDropdown(
                        categories: categories,
                        value: categoryId,
                        onChanged: canCategorize ? onCategoryChanged : null,
                      ),
                      _SubcategoryDropdown(
                        subcategories:
                            selectedCategory?.subcategories ?? const [],
                        value: subcategoryName,
                        onChanged: canCategorize ? onSubcategoryChanged : null,
                      ),
                      _EnumDropdown(
                        label: l10n.impact,
                        value: impact,
                        values: IncidentImpact.values
                            .map(
                              (item) => _Option(
                                item.value,
                                localizedIncidentImpactLabel(l10n, item),
                              ),
                            )
                            .toList(),
                        onChanged: canCategorize ? onImpactChanged : null,
                      ),
                      _EnumDropdown(
                        label: l10n.urgency,
                        value: urgency,
                        values: IncidentUrgency.values
                            .map(
                              (item) => _Option(
                                item.value,
                                localizedIncidentUrgencyLabel(l10n, item),
                              ),
                            )
                            .toList(),
                        onChanged: canCategorize ? onUrgencyChanged : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: canCancel && !isCancelling ? onCancel : null,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          isCancelling ? l10n.cancelling : l10n.cancelTicket,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: canCategorize && !isCategorizing
                            ? onCategorize
                            : null,
                        icon: const Icon(Icons.rule_folder_outlined),
                        label: Text(
                          isCategorizing
                              ? l10n.categorizing
                              : l10n.categorizeTicket,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.workflowStepAssignTicket),
              subtitle: Text(l10n.workflowStepAssignTicketDescription),
              isActive: currentStep >= 2,
              state: ticket.assignedToUserId.trim().isNotEmpty
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StaffDropdown(
                    users: assignableUsers,
                    value: assignedToUserId,
                    onChanged: canAssign ? onAssignedToChanged : null,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: canAssign && !isAssigning ? onAssign : null,
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: Text(
                        isAssigning ? l10n.assigning : l10n.assignTicket,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.workflowStepSolveTicket),
              subtitle: Text(l10n.workflowStepSolveTicketDescription),
              isActive: currentStep >= 3,
              state: isResolved || isClosed
                  ? StepState.complete
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonTextInput(
                    label: l10n.resolutionSummary,
                    hintText: l10n.resolutionSummaryHint,
                    type: CommonTextInputType.text,
                    isMultiline: true,
                    controller: resolutionSummaryController,
                    maxLines: 3,
                    enabled: !isClosed && !isCancelled,
                  ),
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: l10n.resolutionCode,
                    hintText: l10n.resolutionCodeHint,
                    type: CommonTextInputType.text,
                    controller: resolutionCodeController,
                    enabled: !isClosed && !isCancelled,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: canResolve && !isResolving ? onResolve : null,
                      icon: const Icon(Icons.task_alt_outlined),
                      label: Text(
                        isResolving
                            ? l10n.markingSolved
                            : l10n.markTicketSolved,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.workflowStepCloseTicket),
              subtitle: Text(l10n.workflowStepCloseTicketDescription),
              isActive: currentStep >= 4,
              state: isClosed ? StepState.complete : StepState.indexed,
              content: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: canClose && !isClosing ? onClose : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    isClosing ? l10n.closing : l10n.markTicketClosed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _currentStep(IncidentTicket ticket) {
    if (ticket.status == IncidentStatus.closed.value ||
        ticket.lifecycleState == IncidentLifecycleState.closed.value) {
      return 4;
    }
    if (ticket.status == IncidentStatus.resolved.value) {
      return 4;
    }
    if (ticket.assignedToUserId.trim().isNotEmpty) {
      return 3;
    }
    if (ticket.status == IncidentStatus.inProgress.value ||
        ticket.status == IncidentStatus.categorized.value) {
      return 2;
    }
    return 1;
  }

  StepState _categorizationStepState(IncidentTicket ticket) {
    if (ticket.status == IncidentStatus.cancelled.value) {
      return StepState.error;
    }
    if (ticket.categoryId.trim().isNotEmpty &&
        ticket.impact.trim().isNotEmpty &&
        ticket.urgency.trim().isNotEmpty) {
      return StepState.complete;
    }
    return StepState.indexed;
  }
}

class _SubmittedStep extends StatelessWidget {
  const _SubmittedStep({required this.ticket});

  final IncidentTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _Info(label: l10n.title, value: ticket.title),
        _Info(label: l10n.createdBy, value: ticket.createdByName),
        _Info(label: l10n.affectedAgent, value: ticket.affectedUserName),
        _Info(
          label: l10n.blocking,
          value: ticket.isBlocking ? l10n.yes : l10n.no,
        ),
      ],
    );
  }
}

class _RequesterSummary extends StatelessWidget {
  const _RequesterSummary({
    required this.ticket,
  });

  final IncidentTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 40,
              children: [
                _Info(label: l10n.requester, value: ticket.createdByName),
                _Info(label: l10n.email, value: ticket.createdByEmail),
                _Info(
                  label: l10n.department,
                  value: ticket.createdByDepartmentName,
                ),
                _Info(label: l10n.service, value: ticket.createdByServiceName),
                _Info(
                  label: l10n.affectedService,
                  value: ticket.affectedServiceName,
                ),
                _Info(
                  label: l10n.affectedAgent,
                  value: ticket.affectedUserName,
                ),
                _Info(label: l10n.location, value: ticket.location),
                _Info(label: l10n.deviceType, value: ticket.deviceType),
                _Info(label: l10n.assetId, value: ticket.assetId),
                _Info(
                  label: l10n.blocking,
                  value: ticket.isBlocking ? l10n.yes : l10n.no,
                ),
              ],
            ),
            if (ticket.userImpactDescription.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                ticket.userImpactDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
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
  final ValueChanged<String?>? onChanged;

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
  final ValueChanged<String?>? onChanged;

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
  final ValueChanged<String?>? onChanged;

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

class _StaffDropdown extends StatelessWidget {
  const _StaffDropdown({
    required this.users,
    required this.value,
    required this.onChanged,
  });

  final List<IncidentUser> users;
  final String value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final effectiveValue = users.any((user) => user.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.assignedTo,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: '', child: Text(l10n.unassigned)),
        ...users.map(
          (user) => DropdownMenuItem(
            value: user.id,
            child: Text(user.displayName),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EnumDropdown extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<_Option> values;
  final ValueChanged<String?>? onChanged;

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

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
