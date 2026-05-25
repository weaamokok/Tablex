import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';

class TablexSelectionSummaryBar extends StatelessWidget {
  const TablexSelectionSummaryBar({
    super.key,
    required this.count,
    required this.onClear,
    this.actions,
  });

  final int count;
  final VoidCallback onClear;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.primaryContainer,
      child: Row(
        children: [
          Text(
            tablexStrings(context).selected(count),
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          TextButton(
            onPressed: onClear,
            child: Text(tablexStrings(context).clear),
          ),
        ],
      ),
    );
  }
}
