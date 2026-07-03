import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Cabecalho clicavel + conteudo com animacao de expandir/recolher.
class MedicationCollapsibleSection extends StatefulWidget {
  const MedicationCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.initiallyExpanded,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final Widget child;
  final Widget? trailing;

  @override
  State<MedicationCollapsibleSection> createState() =>
      _MedicationCollapsibleSectionState();
}

class _MedicationCollapsibleSectionState
    extends State<MedicationCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(widget.icon,
                      size: 18, color: AppTheme.onSurfaceSecondary(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    widget.trailing!,
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.onSurfaceSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 220),
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: widget.child,
          ),
          secondChild: const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
