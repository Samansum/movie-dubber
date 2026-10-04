import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dub_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renders a pipeline failure: which stage stopped the job, the raw error text,
/// and a copy button for technical users.
///
/// The raw message is deliberately shown verbatim (monospaced, scrollable,
/// never truncated) so a bug report carries the actual error rather than a
/// prettified summary.
class PipelineErrorCard extends StatelessWidget {
  final DubbingTask task;

  /// Whether the long raw detail starts expanded.
  final bool initiallyExpanded;

  const PipelineErrorCard({
    super.key,
    required this.task,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final error = task.error;
    if (error == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(error),
            const SizedBox(height: 10),

            // Short, human-readable summary
            Text(
              error.message,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${error.errorType} • ${error.occurredAt.toIso8601String()}',
              style: AppTypography.codeMono.copyWith(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            _buildRawDetails(context, error),
            const SizedBox(height: 12),

            _buildCopyButton(context),
          ],
        ),
      ),
    );
  }

  /// Header row: error icon plus the name of the stage that failed.
  Widget _buildHeader(DubbingError error) {
    return Row(
      children: [
        const Icon(Icons.error_rounded, color: AppColors.error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pipeline error in ${error.stageTitle}',
            style: AppTypography.headlineSm.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  /// Collapsible panel holding the raw, untruncated error text.
  Widget _buildRawDetails(BuildContext context, DubbingError error) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Text(
          'Raw error message',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(
          Icons.expand_more_rounded,
          color: AppColors.onSurfaceVariant,
        ),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText(
                  error.details.isEmpty ? '(no details captured)' : error.details,
                  style: AppTypography.codeMono.copyWith(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Copies the full technical report (summary + raw detail + stack trace).
  Widget _buildCopyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withOpacity(0.45)),
          backgroundColor: AppColors.error.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => _copyReport(context),
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: Text(
          'Copy error report',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _copyReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: task.errorReport));
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.tertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error report copied to clipboard',
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Could not copy to clipboard: $e',
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
      );
    }
  }
}