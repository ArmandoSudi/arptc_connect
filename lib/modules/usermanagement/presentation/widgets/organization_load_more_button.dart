import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

class OrganizationLoadMoreButton extends StatelessWidget {
  const OrganizationLoadMoreButton({
    required this.loading,
    required this.error,
    required this.onPressed,
    super.key,
  });

  final bool loading;
  final String? error;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          if (error != null) ...[
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: loading ? null : onPressed,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more),
            label: Text(l10n.lookup('umLoadMore')),
          ),
        ],
      ),
    );
  }
}
