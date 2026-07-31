import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

class SupportFilterOption {
  const SupportFilterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class SupportFilterBar extends StatelessWidget {
  const SupportFilterBar({
    required this.searchLabel,
    required this.searchHint,
    required this.onSearchChanged,
    super.key,
    this.searchController,
    this.filters = const [],
    this.trailing,
  });

  final String searchLabel;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController? searchController;
  final List<SupportDropdownFilter> filters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final search = CommonTextInput(
          label: searchLabel,
          hintText: searchHint,
          controller: searchController,
          onChanged: onSearchChanged,
          prefixIcon: const Icon(Icons.search_rounded),
          textInputAction: TextInputAction.search,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              if (filters.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (var index = 0; index < filters.length; index++) ...[
                  filters[index],
                  if (index != filters.length - 1) const SizedBox(height: 12),
                ],
              ],
              if (trailing != null) ...[
                const SizedBox(height: 12),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 2, child: search),
            for (final filter in filters) ...[
              const SizedBox(width: 12),
              Expanded(child: filter),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

class SupportDropdownFilter extends StatelessWidget {
  const SupportDropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String? value;
  final List<SupportFilterOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.value,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
