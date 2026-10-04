import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/dub_models.dart';
import '../services/app_state.dart';
import '../services/edge_tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/animated_waveform.dart';
import '../widgets/glass_card.dart';

class NewDubScreen extends StatefulWidget {
  final AppState state;

  const NewDubScreen({
    super.key,
    required this.state,
  });

  @override
  State<NewDubScreen> createState() => _NewDubScreenState();
}

class _NewDubScreenState extends State<NewDubScreen> {
  bool _isPlayingPreview = false;
  bool _isLoadingVideo = false;
  bool _showAdvancedTuning = false;

  // Selected, on-device video metadata (null = Empty State).
  VideoAsset? _videoAsset;
  VideoPlayerController? _videoController;

  bool get _hasSelectedVideo => _videoAsset != null;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_handleAppStateChange);
  }

  /// Pauses the inline preview when the user navigates away from this tab so
  /// the clip's audio does not keep playing in the background.
  void _handleAppStateChange() {
    if (widget.state.currentTabIndex != 0 && _isPlayingPreview) {
      _pauseVideoPreview();
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_handleAppStateChange);
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickDeviceVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.first.path;
      if (path == null || path.isEmpty) {
        _showErrorSnack('Unable to read the selected video file.');
        return;
      }

      await _loadVideoAsset(path);
    } catch (e) {
      debugPrint('Error picking file: $e');
      _showErrorSnack('Could not load the selected video file.');
    }
  }

  /// Inspects the picked file with the player and builds real [VideoAsset]
  /// metadata (duration, resolution, size) before rendering it on the card.
  Future<void> _loadVideoAsset(String path) async {
    final previousController = _videoController;
    _videoController = null;

    if (mounted) {
      setState(() {
        _isLoadingVideo = true;
        _isPlayingPreview = false;
      });
    }

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      await controller.setLooping(false);
      // Force the very first frame to be decoded so it renders on the card
      // while the preview is paused.
      await controller.seekTo(Duration.zero);

      final size = controller.value.size;
      final sizeBytes = await File(path).length();

      final asset = VideoAsset(
        filePath: path,
        fileName: _fileNameFromPath(path),
        duration: controller.value.duration,
        width: size.width.round(),
        height: size.height.round(),
        sizeBytes: sizeBytes,
      );

      await previousController?.dispose();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onVideoControllerUpdate);
      setState(() {
        _videoController = controller;
        _videoAsset = asset;
        _isLoadingVideo = false;
        _isPlayingPreview = false;
      });
    } catch (e) {
      debugPrint('Error loading video: $e');
      await controller?.dispose();
      await previousController?.dispose();
      if (mounted) {
        setState(() => _isLoadingVideo = false);
        _showErrorSnack('This video could not be loaded for preview.');
      }
    }
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty && segments.last.isNotEmpty
        ? segments.last
        : 'video';
  }

  /// Releases the currently selected clip and resets the viewport back to its
  /// empty state.
  ///
  /// Called right after a job has been handed over to the queue so the user
  /// can pick the next video. The form fields are reset synchronously so the
  /// empty state shows up immediately and a double tap on the CTA cannot
  /// enqueue the same clip twice; the player is released afterwards because
  /// disposing it is asynchronous.
  Future<void> _clearSelectedVideo() async {
    final controller = _videoController;
    _videoController = null;

    if (mounted) {
      setState(() {
        _videoAsset = null;
        _isPlayingPreview = false;
        _isLoadingVideo = false;
      });
    }

    if (controller == null) return;
    controller.removeListener(_onVideoControllerUpdate);
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      }
      await controller.dispose();
    } catch (e) {
      debugPrint('Error releasing video preview: $e');
    }
  }

  /// Keeps the preview flag in sync with the real player state and restores
  /// the overlay controls once playback finishes.
  void _onVideoControllerUpdate() {
    final controller = _videoController;
    if (controller == null || !mounted) return;

    final value = controller.value;

    if (value.isCompleted && _isPlayingPreview) {
      setState(() => _isPlayingPreview = false);
      return;
    }

    if (value.isPlaying != _isPlayingPreview) {
      setState(() => _isPlayingPreview = value.isPlaying);
    }
  }

  Future<void> _startVideoPreview() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isCompleted) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
    if (!mounted) return;
    setState(() => _isPlayingPreview = true);
  }

  /// Tapping the video surface while it plays pauses it and reveals the
  /// hidden overlay controls again.
  Future<void> _pauseVideoPreview() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    }
    if (!mounted) return;
    setState(() => _isPlayingPreview = false);
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMd.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showVideoSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Source Video',
                    style: AppTypography.headlineSm
                        .copyWith(color: AppColors.onSurface),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pick from Device Gallery / File Option
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                tileColor: AppColors.primaryContainer.withOpacity(0.15),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded,
                      color: Colors.white, size: 24),
                ),
                title: Text(
                  'Choose from Gallery or File',
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Select MP4, MOV, or MKV video file from your device',
                  style: AppTypography.bodySm,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDeviceVideo();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _handleVoiceSampleTap(String voiceId, String khmerText) {
    EdgeTtsService().togglePlaySample(
      voiceId: voiceId,
      khmerText: khmerText,
      onStateChanged: () {
        if (mounted) {
          setState(() {
            widget.state.setPlayingVoiceSampleId(
              EdgeTtsService().currentlyPlayingVoiceId,
            );
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cinematic 16:9 Video Viewport Card (Empty State OR Selected Video)
          _buildVideoViewport(),

          const SizedBox(height: 24),

          // 2. Select Voice Mode Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Voice Mode',
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Single Choice • Multi-Speaker Cast or Solo Voice',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Voice Option 1: Smart Multi-Speaker (Auto-Cast)
          _buildVoiceOptionCard(
            profile: VoiceProfile.autoCast,
            isSelected: state.selectedVoice.id == VoiceProfile.autoCast.id,
            onTap: () => state.selectVoice(VoiceProfile.autoCast),
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      VoiceProfile.autoCast.description,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Voice Option 2: Piseth Natural (Male)
          _buildVoiceOptionCard(
            profile: VoiceProfile.pisethNeural,
            isSelected: state.selectedVoice.id == VoiceProfile.pisethNeural.id,
            onTap: () => state.selectVoice(VoiceProfile.pisethNeural),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildVoiceAudioPlayer(VoiceProfile.pisethNeural, state),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Voice Option 3: Sreymon Natural (Female)
          _buildVoiceOptionCard(
            profile: VoiceProfile.sreymomNeural,
            isSelected: state.selectedVoice.id == VoiceProfile.sreymomNeural.id,
            onTap: () => state.selectVoice(VoiceProfile.sreymomNeural),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildVoiceAudioPlayer(VoiceProfile.sreymomNeural, state),
              ],
            ),
          ),

          // const SizedBox(height: 20),
          //
          // // 3. Audio Tuning Controls Accordion
          // GlassCard(
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       InkWell(
          //         onTap: () {
          //           setState(() {
          //             _showAdvancedTuning = !_showAdvancedTuning;
          //           });
          //         },
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Row(
          //               children: [
          //                 const Icon(
          //                   Icons.tune_rounded,
          //                   color: AppColors.secondary,
          //                   size: 20,
          //                 ),
          //                 const SizedBox(width: 8),
          //                 Text(
          //                   'Audio Tuning & Lip-Sync Controls',
          //                   style: AppTypography.labelLg.copyWith(
          //                     fontWeight: FontWeight.w700,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //             Icon(
          //               _showAdvancedTuning
          //                   ? Icons.expand_less_rounded
          //                   : Icons.expand_more_rounded,
          //               color: AppColors.onSurfaceVariant,
          //             ),
          //           ],
          //         ),
          //       ),
          //       if (_showAdvancedTuning) ...[
          //         const SizedBox(height: 16),
          //         const Divider(color: AppColors.borderSubtle, height: 1),
          //         const SizedBox(height: 16),
          //
          //         // Pitch Slider
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text('Voice Pitch Offset', style: AppTypography.labelMd),
          //             Text(
          //               '${state.pitchHz > 0 ? "+${state.pitchHz.toInt()}" : state.pitchHz.toInt()} Hz ${state.pitchHz == 0 ? "(Standard)" : ""}',
          //               style: AppTypography.codeMono,
          //             ),
          //           ],
          //         ),
          //         Slider(
          //           value: state.pitchHz,
          //           min: -10,
          //           max: 10,
          //           divisions: 20,
          //           onChanged: (val) => state.setPitch(val),
          //         ),
          //
          //         // Speed Multiplier Slider
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text('Speech Speed & Cadence',
          //                 style: AppTypography.labelMd),
          //             Text(
          //               '${state.speedMultiplier.toStringAsFixed(2)}x ${state.speedMultiplier == 1.05 ? "(Auto-Align)" : ""}',
          //               style: AppTypography.codeMono,
          //             ),
          //           ],
          //         ),
          //         Slider(
          //           value: state.speedMultiplier,
          //           min: 0.8,
          //           max: 1.4,
          //           divisions: 12,
          //           onChanged: (val) => state.setSpeed(val),
          //         ),
          //
          //         // Audio Ducking Slider
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text('Background Audio Ducking',
          //                 style: AppTypography.labelMd),
          //             Text(
          //               '${state.duckingPercent.toInt()}% (Dialog Clear)',
          //               style: AppTypography.codeMono,
          //             ),
          //           ],
          //         ),
          //         Slider(
          //           value: state.duckingPercent,
          //           min: -50,
          //           max: -10,
          //           divisions: 8,
          //           onChanged: (val) => state.setDucking(val),
          //         ),
          //
          //         // Reset defaults
          //         Align(
          //           alignment: Alignment.centerRight,
          //           child: TextButton.icon(
          //             onPressed: () => state.resetTuning(),
          //             icon: const Icon(Icons.refresh_rounded,
          //                 size: 14, color: AppColors.primary),
          //             label: Text(
          //               'Reset Defaults',
          //               style: AppTypography.labelSm
          //                   .copyWith(color: AppColors.primary),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ],
          //   ),
          // ),

          const SizedBox(height: 24),

          // 4. Primary CTA: "Start AI Khmer Dubbing"
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _hasSelectedVideo
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [
                        AppColors.surfaceContainerHigh,
                        AppColors.surfaceContainerLow,
                      ],
                    ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: _hasSelectedVideo
                  ? const [
                      BoxShadow(
                        color: Color(0x737C3AED),
                        blurRadius: 24,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (!_hasSelectedVideo) {
                    _showVideoSelectorModal();
                    return;
                  }

                  // Snapshot the clip before the form is reset: the job below
                  // needs its metadata while `_clearSelectedVideo` wipes the
                  // viewport back to its empty state.
                  final asset = _videoAsset!;
                  final videoFileName = asset.fileName;

                  state.startNewDubbingJob(
                    videoTitle: videoFileName,
                    duration: asset.durationText,
                    fileSpecs: asset.fileSpecs,
                  );

                  // The clip now belongs to the queue, so drop it from the form
                  // and show the empty state ready for the next pick.
                  await _clearSelectedVideo();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      content: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.tertiary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dubbing pipeline started for $videoFileName!',
                              style: AppTypography.bodyMd
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.tertiaryFixed,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start AI Khmer Dubbing',
                            style: AppTypography.headlineSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasSelectedVideo
                            ? '4-Stage Compute • Est. time: ~1m 20s'
                            : 'Click to select source video first',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimaryContainer.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Video Viewport (Loading / Empty State / Selected Video)
  Widget _buildVideoViewport() {
    if (_isLoadingVideo) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Preparing video preview…',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasSelectedVideo) {
      // Empty State Viewport Card
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryContainer.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showVideoSelectorModal,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryContainer.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.video_library_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Click to select video from gallery or file',
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to pick a video file from your device storage',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Selected Video Viewport Card with Replace Button
    final asset = _videoAsset!;
    final controller = _videoController;
    final isReady = controller != null && controller.value.isInitialized;
    final showOverlays = !_isPlayingPreview;

    // Live video surface: renders the decoded first frame while the preview
    // is paused and the actual frames while it is playing.
    final Widget videoSurface = isReady
        ? Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          )
        : const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // Black backdrop + live video surface. Tapping the surface
                  // while playing pauses playback and reveals the overlays.
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.black),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isPlayingPreview ? _pauseVideoPreview : null,
                      child: videoSurface,
                    ),
                  ),

                  // The controls below are only built while the preview is
                  // paused so that nothing overlays the video during playback.
                  if (showOverlays && isReady) ...[
                    // Gradient Scrim
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x990A0E16),
                              Colors.transparent,
                              Color(0xCC0A0E16),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Top Badges Overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest
                                  .withOpacity(0.85),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppColors.borderSubtle, width: 0.5),
                            ),
                            child: Text(
                              asset.resolutionLabel,
                              style:
                                  AppTypography.codeMono.copyWith(fontSize: 11),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest
                                  .withOpacity(0.85),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppColors.borderSubtle, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.tertiary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  asset.durationText,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Play Button (visible only while paused)
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _startVideoPreview,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryContainer.withOpacity(0.9),
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
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom Meta & Replace Action
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  asset.fileName,
                                  style: AppTypography.headlineSm.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.album_outlined,
                                      color: AppColors.onSurfaceVariant,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        asset.fileSpecs,
                                        style: AppTypography.bodySm.copyWith(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showVideoSelectorModal,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surfaceBright.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Replace',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds consistent audio player UI for Piseth Natural and Sreymon Natural
  Widget _buildVoiceAudioPlayer(VoiceProfile profile, AppState state) {
    final isPlaying = state.playingVoiceSampleId == profile.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          // Play / Speaker Icon Button
          InkWell(
            onTap: () => _handleVoiceSampleTap(
              profile.id,
              profile.khmerSampleText,
            ),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? Colors.white : AppColors.onSurface,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Audio Content: Waveform when playing vs Quote text when idle
          Expanded(
            child: isPlaying
                ? const Row(
                    children: [
                      Expanded(
                        child: AnimatedWaveform(
                          isPlaying: true,
                          barCount: 16,
                          height: 18,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Sample: «${profile.khmerSampleText}»',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 8),

          Text(
            profile.durationText,
            style: AppTypography.codeMono.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOptionCard({
    required VoiceProfile profile,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.surfaceContainerHigh
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected ? AppColors.primaryContainer : AppColors.borderSubtle,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Avatar or Emblem
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                            image: profile.imagePath.isNotEmpty
                                ? DecorationImage(
                                    image: AssetImage(profile.imagePath),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profile.imagePath.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.group_work_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.name,
                                  style: AppTypography.headlineSm.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: profile.type == VoiceType.autoCast
                                        ? AppColors.tertiaryContainer
                                            .withOpacity(0.3)
                                        : (profile.type == VoiceType.male
                                            ? AppColors.primary.withOpacity(0.2)
                                            : AppColors.secondary
                                                .withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    profile.badgeText,
                                    style: AppTypography.labelSm.copyWith(
                                      color: profile.type == VoiceType.autoCast
                                          ? AppColors.tertiary
                                          : (profile.type == VoiceType.male
                                              ? AppColors.primary
                                              : AppColors.secondary),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.roleTag,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Radio indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceBright,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.onPrimary,
                                size: 16,
                              )
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
