import 'package:flutter/material.dart';
import '../l10n/app_l10n.dart';
import '../models/dub_models.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/pipeline_error_card.dart';
import '../widgets/pipeline_stage_tile.dart';

class QueueScreen extends StatelessWidget {
  final AppState state;

  const QueueScreen({
    super.key,
    required this.state,
  });

  void _showTerminateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).terminateProcessTitle, style: AppTypography.headlineSm),
          ],
        ),
        content: Text(
          'Are you sure you want to stop the ongoing translation and TTS synthesis? This will abort the current video render.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.onErrorContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              state.terminateActiveProcess();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceContainerHighest,
                  content: Text(
                    AppLocalizations.of(context).processTerminated,
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.error),
                  ),
                ),
              );
            },
            child: Text(AppLocalizations.of(context).terminateConfirm, style: AppTypography.labelMd.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  /// Confirmation modal for dropping a job that is still waiting in the queue.
  void _showRemoveFromQueueDialog(BuildContext context, DubbingTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.playlist_remove_rounded,
                color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).removeFromQueueTitle, style: AppTypography.headlineSm),
          ],
        ),
        content: Text(
          AppLocalizations.of(context).removeFromQueueBody(task.videoTitle),
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningContainer,
              foregroundColor: AppColors.onSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              final removed = state.removeQueuedTask(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceContainerHighest,
                  content: Text(
                    removed
                        ? AppLocalizations.of(context).removedFromQueue(task.videoTitle)
                        : AppLocalizations.of(context).jobNoLongerInQueue,
                    style: AppTypography.bodyMd.copyWith(
                      color: removed
                          ? AppColors.warning
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
            child: Text(AppLocalizations.of(context).removeConfirm),
          ),
        ],
      ),
    );
  }

  /// Shown when the pipeline has no active, queued or completed jobs.
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.movie_filter_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).emptyStateEmptyQueue,
            style: AppTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).emptyStateEmptyQueueBody,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = state.activeTask;
    final queued = state.queuedTasks;
    final completed = state.completedTasks;
    final failed = state.failedTasks;

    final bool hasActive = active != null && active.isProcessing;
    final bool hasAnything = active != null ||
        queued.isNotEmpty ||
        completed.isNotEmpty ||
        failed.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Queue Summary Title Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).screenQueueTitle,
                    style: AppTypography.headlineLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context).screenQueueSubtitle,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).syncLive,
                      style: AppTypography.codeMono
                          .copyWith(fontSize: 10, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Status Summary Pills
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${hasActive ? 1 : 0} Active',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x26F59E0B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x4DF59E0B)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${queued.length} Queued',
                      style: AppTypography.labelSm.copyWith(
                        color: const Color(0xFFFDE68A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppColors.tertiary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${completed.length} Done',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${failed.length} Failed',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // EMPTY STATE: shown only when the pipeline has no jobs at all
          if (!hasAnything) _buildEmptyState(context),

          // CARD 1: CURRENTLY PROCESSING VIDEO (only while a job is running)
          if (active != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active.isProcessing
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.borderSubtle,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active.isProcessing
                        ? AppColors.primaryContainer.withOpacity(0.18)
                        : const Color(0x33000000),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Title & Processing Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.smart_display_rounded,
                                    color: AppColors.secondary,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${active.duration} • Voice: ${active.voiceProfile.name}',
                                    style: AppTypography.codeMono.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                active.videoTitle,
                                style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (active.isProcessing)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                active.isProcessing
                                    ? '${(active.progress * 100).toInt()}%'
                                    : '100%',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Overall Gradient Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 6,
                        color: AppColors.surfaceContainerLowest,
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: active.progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.primary
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4-Stage Progression Flow
                    Text(
                      'PIPELINE STAGE PROGRESSION',
                      style: AppTypography.labelSm.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...active.stages
                        .map((stage) => PipelineStageTile(stage: stage)),

                    const SizedBox(height: 8),

                    // Real-time Console Log Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppColors.surfaceContainerLowest.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.terminal_rounded,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              active.liveStatusLog,
                              style: AppTypography.codeMono.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (active.isProcessing) ...[
                      const SizedBox(height: 14),
                      // Terminate Process Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF87171),
                            side: BorderSide(
                              color: const Color(0xFFEF4444).withOpacity(0.35),
                            ),
                            backgroundColor:
                                const Color(0xFFEF4444).withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showTerminateDialog(context),
                          icon:
                              const Icon(Icons.stop_circle_outlined, size: 18),
                          label: Text(
                             AppLocalizations.of(context).terminateProcessTitle,
                            style: AppTypography.labelMd.copyWith(
                              color: const Color(0xFFF87171),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // CARD 2: FAILED JOBS — shown above the queue so a stopped pipeline is the
          // first thing the user sees, with its raw error and a copy button.
          if (failed.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).failedJobs,
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'These renders stopped on an error. Stages before the failure are '
              'marked completed; everything after it did not run.',
              style: AppTypography.bodySm.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 10),
            ...failed.map((item) {
              final error = item.error!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam_rounded,
                          color: AppColors.onSurfaceVariant, size: 15),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.videoTitle,
                          style: AppTypography.headlineSm.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: AppColors.error.withOpacity(0.45)),
                        ),
                        child: Text(
                          'FAILED • STAGE ${error.stageIndex + 1}',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stage-by-stage breakdown: what finished, what stopped.
                  // The failed stage offers a retry that resumes from there.
                  ...item.stages.asMap().entries.map((entry) {
                    final stageIndex = entry.key;
                    final stage = entry.value;
                    return PipelineStageTile(
                      stage: stage,
                      retryEnabled: !state.isPipelineBusy,
                      onRetry: stage.status == StageStatus.failed
                          ? () => state.retryFailedStage(
                                item.id,
                                fromStage: stageIndex,
                              )
                          : null,
                    );
                  }),

                  const SizedBox(height: 4),

                  // Remove the failed job from the screen, above the error.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        side: BorderSide(color: AppColors.borderSubtle),
                        backgroundColor: AppColors.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        final removed = state.removeFailedTask(item.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceContainerHighest,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            content: Text(
                              removed
                                  ? AppLocalizations.of(context).removedFromQueue(item.videoTitle)
                                  : AppLocalizations.of(context).jobNoLongerInQueue,
                              style: AppTypography.bodyMd.copyWith(
                                color: removed
                                    ? AppColors.onSurface
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        AppLocalizations.of(context).removeConfirm,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Raw error + copy button.
                  PipelineErrorCard(task: item),
                ],
              );
            }),
          ],

          // CARD 3: QUEUED VIDEOS
          if (queued.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'QUEUED VIDEOS',
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ...queued.asMap().entries.map(
              (entry) {
                final item = entry.value;
                final queuePosition = entry.key + 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      color: AppColors.warning,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${item.duration} • Voice: ${item.voiceProfile.name}',
                                      style: AppTypography.codeMono.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.videoTitle,
                                  style: AppTypography.headlineSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x26F59E0B),
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0x4DF59E0B)),
                            ),
                            child: Text(
                              'QUEUED #$queuePosition',
                              style: AppTypography.labelSm.copyWith(
                                color: const Color(0xFFFDE68A),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.surfaceContainerLowest.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_empty_rounded,
                              color: AppColors.warning,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Awaiting worker slot • Will execute after active render',
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Drop this job from the queue before it gets a worker slot
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: BorderSide(
                              color: AppColors.warning.withOpacity(0.35),
                            ),
                            backgroundColor:
                                AppColors.warning.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              _showRemoveFromQueueDialog(context, item),
                          icon: const Icon(Icons.playlist_remove_rounded,
                              size: 18),
                          label: Text(
                            AppLocalizations.of(context).removeFromQueueTooltip,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          // CARD 4: COMPLETED VIDEOS
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).completedRecentJobs,
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ...completed.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x334EDEA3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.tertiary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.videoTitle,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.fileSpecs} • Voice: ${item.voiceProfile.name}',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        // Opens THIS job's render in the Player tab.
                        state.openTaskInPlayer(item);
                      },
                      child: Text(
                        'Play',
                        style: AppTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
