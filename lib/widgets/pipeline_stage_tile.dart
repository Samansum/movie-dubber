import 'package:flutter/material.dart';
import '../models/dub_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PipelineStageTile extends StatelessWidget {
  final PipelineStage stage;

  /// When provided, a failed stage shows a "Retry" button that re-runs just
  /// this step. `null` hides the button.
  final VoidCallback? onRetry;

  /// Whether the retry button accepts taps (e.g. a job is already running).
  final bool retryEnabled;

  const PipelineStageTile({
    super.key,
    required this.stage,
    this.onRetry,
    this.retryEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Color containerColor;
    Color borderColor;
    Color iconColor;
    Color iconBgColor;
    Widget statusBadge;

    switch (stage.status) {
      case StageStatus.completed:
        containerColor = AppColors.surfaceContainerLow.withOpacity(0.8);
        borderColor = const Color(0x334EDEA3);
        iconColor = AppColors.tertiary;
        iconBgColor = AppColors.tertiaryContainer.withOpacity(0.3);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            stage.badgeText,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        break;

      case StageStatus.inProgress:
        containerColor = AppColors.primaryContainer.withOpacity(0.12);
        borderColor = AppColors.primary.withOpacity(0.5);
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primaryContainer.withOpacity(0.35);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                stage.badgeText,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        break;

      case StageStatus.failed:
        containerColor = AppColors.errorContainer.withOpacity(0.12);
        borderColor = AppColors.error.withOpacity(0.45);
        iconColor = AppColors.error;
        iconBgColor = AppColors.errorContainer.withOpacity(0.3);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.error.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.priority_high_rounded,
                  color: AppColors.error, size: 10),
              const SizedBox(width: 3),
              Text(
                stage.badgeText,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        break;

      case StageStatus.nextUp:
        containerColor = AppColors.surfaceContainerLow.withOpacity(0.5);
        borderColor = AppColors.outlineVariant.withOpacity(0.2);
        iconColor = AppColors.outline;
        iconBgColor = AppColors.surfaceContainerHigh;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            stage.badgeText,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        );
        break;

      case StageStatus.pending:
      default:
        containerColor = AppColors.surfaceContainerLow.withOpacity(0.35);
        borderColor = AppColors.outlineVariant.withOpacity(0.15);
        iconColor = AppColors.outline.withOpacity(0.6);
        iconBgColor = AppColors.surfaceContainerHigh.withOpacity(0.5);
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withOpacity(0.6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            stage.badgeText,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.outline,
            ),
          ),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: stage.status == StageStatus.inProgress
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(
                      stage.icon,
                      color: iconColor,
                      size: 16,
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: stage.status == StageStatus.inProgress ||
                            stage.status == StageStatus.failed
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: stage.status == StageStatus.inProgress
                        ? AppColors.primary
                        : stage.status == StageStatus.failed
                            ? AppColors.error
                            : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.description,
                  style: AppTypography.bodySm.copyWith(
                    color: stage.status == StageStatus.completed
                        ? AppColors.tertiary
                        : stage.status == StageStatus.failed
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Only a failed stage offers a retry, and only when the caller
                // supplied a handler (nothing to retry for other statuses).
                if (stage.status == StageStatus.failed && onRetry != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.45),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: retryEnabled ? onRetry : null,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(
                        'Retry this stage',
                        style: AppTypography.labelSm.copyWith(
                          color: retryEnabled
                              ? AppColors.primary
                              : AppColors.outline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          statusBadge,
        ],
      ),
    );
  }
}
