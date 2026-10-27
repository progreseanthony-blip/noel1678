import 'package:flutter/material.dart';
import '../utils/machinery_progress.dart';

String _fmt(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

class MachineryProgressPanel extends StatelessWidget {
  final List<ProductionMeasure> measures;
  final String title;
  final String? note;
  final bool compact;
  final String contributionLabel;
  const MachineryProgressPanel({
    super.key,
    required this.measures,
    required this.title,
    this.note,
    this.compact = false,
    this.contributionLabel = 'This crew today',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (measures.isEmpty)
      return Text(
        'Production target not available',
        style: theme.textTheme.bodySmall,
      );
    final volume = measures.any((m) => m.unit == 'CY');
    final shown = measures.where((m) => !(volume && m.unit == 'trips'));
    return Container(
      padding: EdgeInsets.all(compact ? 4 : 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) Text(title, style: theme.textTheme.labelLarge),
          for (final m in shown)
            Tooltip(
              message:
                  'Daily plan: ${_fmt(m.dailyPlan)} ${m.unit}\nToday’s production: ${_fmt(m.today)} ${m.unit}\n$contributionLabel: ${_fmt(m.crewToday)} ${m.unit}${note == null ? '' : '\n$note'}',
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.hasPlan
                          ? 'To date: ${_fmt(m.actualToDate)} / ${_fmt(m.plannedToDate)} ${m.unit}${m.plannedToDate > 0 ? ' · ${_fmt(m.actualToDate / m.plannedToDate * 100)}%' : ''}'
                          : 'To date: ${_fmt(m.actualToDate)} ${m.unit} · Plan dates not available',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (m.hasPlan) ...[
                      const SizedBox(height: 4),
                      ProductionComparisonBar(
                        planned: m.plannedToDate,
                        actual: m.actualToDate,
                        unit: m.unit,
                        compact: compact,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One accumulated execution bar with a plan marker on the same scale.
class ProductionComparisonBar extends StatelessWidget {
  final double planned, actual;
  final String unit;
  final bool compact;
  const ProductionComparisonBar({
    super.key,
    required this.planned,
    required this.actual,
    required this.unit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = (planned > actual ? planned : actual).clamp(
      0.0,
      double.infinity,
    );
    final planRatio = scale > 0 ? (planned / scale).clamp(0.0, 1.0) : 0.0;
    final difference = actual - planned;
    final description =
        'Plan: ${_fmt(planned)} $unit · Actual: ${_fmt(actual)} $unit · ${difference >= 0 ? '+' : ''}${_fmt(difference)} $unit vs plan';
    return Tooltip(
      message: '$description\nVertical mark: planned to date',
      child: Semantics(
        label: description,
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: compact ? 8 : 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  value: scale > 0 ? (actual / scale).clamp(0.0, 1.0) : 0,
                  minHeight: compact ? 4 : 6,
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                Positioned(
                  left:
                      (constraints.maxWidth - 2).clamp(0.0, double.infinity) *
                      planRatio,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    key: const ValueKey('production-plan-marker'),
                    width: 2,
                    child: ColoredBox(color: theme.colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
