import 'package:arptc_connect/core/theme.dart';
import 'package:flutter/material.dart';

class ItsmNavigationCard extends StatefulWidget {
  const ItsmNavigationCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.count,
    this.cardKey,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final int? count;
  final Key? cardKey;

  @override
  State<ItsmNavigationCard> createState() => _ItsmNavigationCardState();
}

class _ItsmNavigationCardState extends State<ItsmNavigationCard> {
  var _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.corporateTheme;

    return Semantics(
      button: true,
      label: widget.title,
      child: Focus(
        onFocusChange: _setHighlighted,
        child: MouseRegion(
          onEnter: (_) => _setHighlighted(true),
          onExit: (_) => _setHighlighted(false),
          child: AnimatedContainer(
            key: widget.cardKey,
            duration: const Duration(milliseconds: 160),
            transform: Matrix4.translationValues(0, _highlighted ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: _highlighted
                    ? widget.color.withOpacity(0.7)
                    : tokens.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.cardShadow,
                  blurRadius: _highlighted ? 18 : 10,
                  offset: Offset(0, _highlighted ? 8 : 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                canRequestFocus: true,
                borderRadius: BorderRadius.circular(tokens.cardRadius),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => widget.color.withOpacity(
                    states.contains(WidgetState.pressed) ? 0.14 : 0.08,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (widget.count != null)
                                  _CountBadge(
                                    count: widget.count!,
                                    color: widget.color,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHighlighted(bool value) {
    if (_highlighted == value || !mounted) {
      return;
    }
    setState(() => _highlighted = value);
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
