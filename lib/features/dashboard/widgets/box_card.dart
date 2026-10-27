import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../models/dashboard_box_summary.dart';

class BoxCard extends StatelessWidget {
  const BoxCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onSellerTap,
  });

  final DashboardBoxSummary summary;
  final VoidCallback onTap;
  final VoidCallback onSellerTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final textTheme = Theme.of(context).textTheme;
    final vacant = summary.isVacant;

    // A vacant box is the one a cashier is looking for when a new seller walks in,
    // so it gets the only colour on the grid; occupied boxes stay white and quiet.
    final background = vacant ? AppColors.vacantSoft : AppColors.surface;
    final border = vacant ? AppColors.vacant.withValues(alpha: 0.35) : AppColors.line;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'BOX ${summary.boxNumber}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                  _StatusPill(vacant: vacant),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: summary.sellerId == null ? null : onSellerTap,
                child: Text(
                  summary.sellerName ?? 'Ready to rent',
                  style: textTheme.bodyLarge?.copyWith(
                    color: vacant ? AppColors.vacant : AppColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                vacant ? 'Tap to occupy' : 'Sales',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currency.format(summary.total),
                    style: textTheme.headlineSmall?.copyWith(
                      color: vacant ? AppColors.muted : AppColors.ink,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.vacant});

  final bool vacant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: vacant ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: vacant ? AppColors.vacant.withValues(alpha: 0.35) : AppColors.line),
      ),
      child: Text(
        vacant ? 'Vacant' : 'Occupied',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: vacant ? AppColors.vacant : AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
