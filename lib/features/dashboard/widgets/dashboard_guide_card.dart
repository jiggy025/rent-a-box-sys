import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../models/dashboard_guide_state.dart';

class DashboardGuideCard extends StatelessWidget {
  const DashboardGuideCard({
    required this.state,
    required this.onOpenHelp,
    required this.onDismissRefresher,
    super.key,
  });

  static const setupSteps = <String>[
    '1. Add seller',
    '2. Add box',
    '3. Occupy vacant box',
    '4. Tap box to add sales',
    '5. Manage seller payouts',
  ];

  final DashboardGuideState state;
  final VoidCallback onOpenHelp;
  final VoidCallback onDismissRefresher;

  /// Whether each setup step is already done, read from the shop's real counts,
  /// in the same order as [setupSteps].
  List<bool> get _stepsDone => [
        state.hasSeller,
        state.hasActiveBox,
        state.hasActiveAssignment,
        state.logEntryCount > 0,
        state.sellerAdjustmentCount > 0,
      ];

  @override
  Widget build(BuildContext context) {
    if (!state.showAnyGuideCard) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: state.showCompactRefresher ? _buildRefresher(context) : _buildSetup(context),
      ),
    );
  }

  /// First run: a checklist that ticks itself off as the shop is set up.
  Widget _buildSetup(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = _stepsDone;
    final doneCount = done.where((d) => d).length;
    final nextIndex = done.indexOf(false); // -1 when every step is done

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text('Get your dashboard ready', style: textTheme.titleLarge),
            ),
            Text(
              '$doneCount of ${setupSteps.length} done',
              style: textTheme.bodySmall?.copyWith(fontFeatures: tabularFigures),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: doneCount / setupSteps.length,
            minHeight: 6,
            backgroundColor: AppColors.line,
            valueColor: const AlwaysStoppedAnimation(AppColors.vacant),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < setupSteps.length; i++)
          _StepRow(
            label: setupSteps[i],
            status: done[i]
                ? _StepStatus.done
                : i == nextIndex
                    ? _StepStatus.next
                    : _StepStatus.todo,
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onOpenHelp,
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Open help'),
        ),
      ],
    );
  }

  /// After setup: a small, dismissible summary of what the shop holds.
  Widget _buildRefresher(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text('Need a quick refresher?', style: textTheme.titleMedium),
            ),
            IconButton(
              key: const Key('dashboard-refresher-close'),
              onPressed: onDismissRefresher,
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss refresher',
              visualDensity: VisualDensity.compact,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Dashboard setup complete',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountChip(label: 'Sellers', value: state.sellerCount),
            _CountChip(label: 'Boxes', value: state.activeBoxCount),
            _CountChip(label: 'Assignments', value: state.activeAssignmentCount),
            _CountChip(label: 'Sales', value: state.logEntryCount),
            _CountChip(label: 'Payouts', value: state.sellerAdjustmentCount),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onOpenHelp,
          icon: const Icon(Icons.help_outline),
          label: const Text('Open help'),
        ),
      ],
    );
  }
}

enum _StepStatus { done, next, todo }

/// One checklist line: a status mark, then the step. The next step to do is the only one in colour.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Widget mark = switch (status) {
      _StepStatus.done => Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.vacant, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        ),
      _StepStatus.next => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
          ),
        ),
      _StepStatus.todo => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lineStrong, width: 1.5),
          ),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: switch (status) {
                _StepStatus.done => textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                _StepStatus.next => textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                _StepStatus.todo => textTheme.bodyMedium?.copyWith(color: AppColors.ink2),
              },
            ),
          ),
          if (status == _StepStatus.next)
            Text(
              'Next',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label ', style: textTheme.labelMedium?.copyWith(color: AppColors.muted)),
            TextSpan(
              text: '$value',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
