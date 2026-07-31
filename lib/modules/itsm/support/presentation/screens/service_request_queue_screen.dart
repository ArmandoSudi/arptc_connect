import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/support_providers.dart';
import '../../data/service_request_repository.dart';
import '../../domain/service_request.dart';
import '../widgets/service_request_list_view.dart';

class ServiceRequestQueueScreen extends ConsumerStatefulWidget {
  const ServiceRequestQueueScreen({super.key, this.onRequestSelected});

  final ValueChanged<ServiceRequest>? onRequestSelected;

  @override
  ConsumerState<ServiceRequestQueueScreen> createState() =>
      _ServiceRequestQueueScreenState();
}

class _ServiceRequestQueueScreenState
    extends ConsumerState<ServiceRequestQueueScreen> {
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final request = ServiceRequestFirstPageRequest(
      query: ServiceRequestQuery(
        scope: ServiceRequestScope.managerActive,
        searchTerm: _search,
      ),
    );
    final requests = ref.watch(serviceRequestFirstPageProvider(request));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itsmServiceRequests)),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () =>
              ref.invalidate(serviceRequestFirstPageProvider(request)),
        ),
        data: (values) => ServiceRequestListView(
          requests: values,
          searchQuery: _search,
          showRequester: true,
          onSearchChanged: (value) => setState(() => _search = value),
          onSelected: widget.onRequestSelected ?? (_) {},
        ),
      ),
    );
  }
}
