import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_l10n.dart';
import '../models/dub_models.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

/// Studio Player for a rendered dub.
///
/// Plays the real MP4 produced by the pipeline ([DubbingTask.outputPath]) with
/// `video_player`, and offers a single "Save to Gallery" action that copies the
/// file into the device's Movies/Videos collection.
class CompletedPlayerScreen extends StatefulWidget {
  final AppState state;

  const CompletedPlayerScreen({
    super.key,
    required this.state,
  });

  @override
  State<CompletedPlayerScreen> createState() => _CompletedPlayerScreenState();
}

class _CompletedPlayerScreenState extends State<CompletedPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;

  /// Raw failure text when the rendered file cannot be played.
  String? _loadError;

  /// Guards against touching state after the widget is gone.
  bool _disposed = false;

  /// Id of the job currently loaded into [_controller].
  String? _loadedTaskId;

  /// Corner radius shared by the video card and its clipped content, so the
  /// picture meets the card edge with matching corners and no padding.
  static const double _videoRadius = 18;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _loadFor(widget.state.playerTask);
  }

  @override
  void dispose() {
    _disposed = true;
    widget.state.removeListener(_onStateChanged);
    _controller?.removeListener(_onPlaybackTick);
    _controller?.dispose();
    super.dispose();
  }

  /// Rebuilds the player whenever a different job is opened in the Player tab.
  void _onStateChanged() {
    final task = widget.state.playerTask;
    if (task?.id != _loadedTaskId) {
      _loadFor(task);
    }
  }

  /// Points the player at [task]'s rendered output, tearing down any previous
  /// controller first.
  Future<void> _loadFor(DubbingTask? task) async {
    final path = task?.outputPath;

    // Nothing rendered yet, or the render has no playable output.
    if (task == null || path == null || path.isEmpty) {
      _loadedTaskId = task?.id;
      await _teardownController();
      if (_disposed) return;
      setState(() {
        _isLoading = false;
        _loadError =
            task == null ? null : 'This job has no rendered video file yet.';
      });
      return;
    }

    _loadedTaskId = task.id;
    await _teardownController();
    if (_disposed) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final file = File(path);
    if (!file.existsSync()) {
      setState(() {
        _isLoading = false;
        _loadError = 'The rendered video no longer exists on disk:\n$path';
      });
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (_disposed) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onPlaybackTick);

      // Start playing straight away so the user does not have to tap play
      // after opening the job from the Queue screen.
      await controller.play();

      if (_disposed) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      await controller.dispose();
      if (_disposed) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not open this video:\n$e';
      });
    }
  }

  Future<void> _teardownController() async {
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onPlaybackTick);
      await old.pause();
      await old.dispose();
    }
  }

  /// Keeps the play/pause badge and the scrubber in sync with the decoder.
  void _onPlaybackTick() {
    if (_disposed || !mounted) return;
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != widget.state.isPlayingVideo) {
      widget.state.setPlayingVideo(playing);
    }
    setState(() {});
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      // Replay from the start once the video has run to the end.
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  void _seekTo(double fraction) {
    final controller = _controller;
    if (controller == null) return;
    final total = controller.value.duration;
    controller.seekTo(Duration(
      milliseconds: (total.inMilliseconds * fraction).round(),
    ));
  }

  /// Scrubber position in `0.0..1.0`, guarding against an unknown duration.
  double _progressOf(VideoPlayerController controller) {
    final total = controller.value.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (controller.value.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    final totalSec = d.inSeconds;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Builds the screen body: banner, real player, and the Save action.
  @override
  Widget build(BuildContext context) {
    final task = widget.state.playerTask;

    if (task == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: _buildEmptyState(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(task),
          const SizedBox(height: 16),
          _buildVideoViewport(),
          const SizedBox(height: 24),
          _buildSaveButton(),
          const SizedBox(height: 16),
          // The button always stays put; success is confirmed below it.
          // if (widget.state.saveGalleryState == 'saved') ...[
          //   const SizedBox(height: 12),
          //   _buildSavedConfirmation(),
          // ],
          // if (widget.state.saveGalleryError != null) ...[
          //   const SizedBox(height: 12),
          //   _buildSaveError(),
          // ],
        ],
      ),
    );
  }

  /// Shown when no successful render exists yet.
  Widget _buildEmptyState() {
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
              color: AppColors.tertiaryContainer.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.movie_filter_rounded,
                  color: AppColors.tertiary, size: 26),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).emptyStateEmptyPlayer,
            style:
                AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).emptyStateEmptyPlayerBody,
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

  /// Telemetry header bound to the real job instead of hard-coded values.
  Widget _buildBanner(DubbingTask task) {
    final controller = _controller;
    final duration = controller?.value.duration;
    final position = controller?.value.position;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.videoTitle,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                task.fileSpecs,
                style: AppTypography.codeMono.copyWith(
                  color: AppColors.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              AppLocalizations.of(context).voiceLabel(task.voiceProfile.name),
              style: AppTypography.bodySm.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (position != null &&
                duration != null &&
                duration.inMilliseconds > 0) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).playbackLabel(_formatDuration(position), _formatDuration(duration)),
                style: AppTypography.codeMono.copyWith(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  /// Viewport rendering the real decoded frames edge-to-edge inside a card.
  ///
  /// Tapping anywhere on the picture toggles playback. While the video is
  /// playing no overlay is drawn at all; the play button only appears once the
  /// user has paused it (or it reached the end).
  Widget _buildVideoViewport() {
    final controller = _controller;
    final ready = !_isLoading && _loadError == null && controller != null;
    final isPlaying = ready && controller.value.isPlaying;
    final radius = BorderRadius.circular(_videoRadius);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // No padding: the video runs to the very edge of the card.
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_isLoading)
                Container(
                  color: AppColors.surfaceContainerLowest,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              else if (_loadError != null)
                Container(
                  color: AppColors.surfaceContainerLowest,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_rounded,
                            color: AppColors.error, size: 32),
                        const SizedBox(height: 10),
                        SelectableText(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                VideoPlayer(controller!),

              // Whole-surface tap target. Sits *below* the play button and the
              // scrubber so those keep their own gestures.
              if (ready)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlay,
                ),

              // Play button: only while paused.
              if (ready && !isPlaying) Center(child: _buildPlayButton()),

              // Bottom scrubber
              if (ready)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xCC000000)],
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: _progressOf(controller),
                        onChanged: _seekTo,
                      ),
                    ),
                  ),
                ),

              // Border painted last so it is not covered by the video.
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: AppColors.borderSubtle, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Centered play trigger, shown only when the video is paused.
  Widget _buildPlayButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _togglePlay,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x807C3AED),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }

  /// Primary action: copies the rendered video into the device's Videos dir.
  Widget _buildSaveButton() {
    final saveState = widget.state.saveGalleryState;
    final isBusy = saveState == 'saving';
    final isSaved = saveState == 'saved';

    final (label, icon) = switch (saveState) {
      'saving' => (AppLocalizations.of(context).savingLabel, null),
      'saved' => (AppLocalizations.of(context).savedLabel, Icons.check_circle_rounded),
      'error' => (AppLocalizations.of(context).retrySaveToGalleryLabel, Icons.error_rounded),
      _ => (AppLocalizations.of(context).saveToGallery, Icons.download_for_offline_rounded),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isSaved
            ? const LinearGradient(
                colors: [Color(0xFF007650), Color(0xFF10B981)])
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF732EE4)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x667C3AED),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy || isSaved ? null : () => widget.state.saveToGallery(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBusy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTypography.headlineSm.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Raw reason the last save attempt failed.
  Widget _buildSaveError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              widget.state.saveGalleryError!,
              style: AppTypography.codeMono.copyWith(
                fontSize: 11,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
