import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

import '../../domain/service_request.dart';

class ServiceRequestListView extends StatelessWidget {
  const ServiceRequestListView({
    required this.requests,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelected,
    super.key,
    this.showRequester = false,
  });

  final List<ServiceRequest> requests;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ServiceRequest> onSelected;
  final bool showRequester;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: CommonTextInput(
              label: l10n.search,
              hintText: l10n.itsmServiceRequests,
              prefixIcon: const Icon(Icons.search),
              onChanged: onSearchChanged,
            ),
          ),
        ),
        if (requests.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              icon: Icons.inbox_outlined,
              title: l10n.noDataAvailable,
              description: l10n.noDataDescription,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.separated(
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _RequestCard(
                  request: request,
                  showRequester: showRequester,
                  onTap: () => onSelected(request),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.showRequester,
    required this.onTap,
  });

  final ServiceRequest request;
  final bool showRequester;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return CorporateSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final details = [
            _Meta(
              icon: Icons.category_outlined,
              text: request.catalogueItemName,
            ),
            if (showRequester)
              _Meta(
                icon: Icons.person_outline,
                text: request.requestedForName,
              ),
            _Meta(
              icon: Icons.schedule_outlined,
              text: localizations.formatMediumDate(request.updatedAt),
            ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                _RequestHeading(request: request),
                const SizedBox(height: 12),
                _StatusChip(status: request.status),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _RequestHeading(request: request)),
                    const SizedBox(width: 16),
                    _StatusChip(status: request.status),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(spacing: 18, runSpacing: 8, children: details),
              if (request.sla != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: request.sla!.status.name == 'breached' ? 1 : .55,
                  color: request.sla!.status.name == 'breached'
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RequestHeading extends StatelessWidget {
  const _RequestHeading({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.requestNumber,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          request.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ServiceRequestStatus.rejected ||
      ServiceRequestStatus.cancelled =>
        Theme.of(context).colorScheme.error,
      ServiceRequestStatus.closed ||
      ServiceRequestStatus.fulfilled =>
        Colors.green,
      ServiceRequestStatus.awaitingApproval => Colors.orange,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Chip(
      avatar: Icon(Icons.circle, size: 10, color: color),
      label: Text(status.value.replaceAll('_', ' ')),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
