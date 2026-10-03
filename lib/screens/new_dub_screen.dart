import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  bool _showAdvancedTuning = false;

  // Video Selection State (null = Empty State)
  int? _selectedVideoIndex;
  String? _customVideoTitle;
  String? _customDuration;
  String? _customSpecs;
  String? _customImagePath;

  final List<Map<String, String>> _sampleVideos = [
    {
      'title': 'Cyber_Action_Trailer_1080p.mp4',
      'duration': '02:45',
      'specs': '48.2 MB • H.264 / AAC • 1080p 60fps',
      'image':
          'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Angkor_Heritage_Doc_Clip.mp4',
      'duration': '04:10',
      'specs': '68.5 MB • ProRes / AAC • 4K 24fps',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Tokyo_Neon_Night_Vlog.mp4',
      'duration': '01:30',
      'specs': '32.1 MB • H.265 / AAC • 1080p 30fps',
      'image':
          'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800&auto=format&fit=crop&q=80',
    },
  ];

  bool get _hasSelectedVideo =>
      _selectedVideoIndex != null || _customVideoTitle != null;

  String get _currentVideoTitle {
    if (_customVideoTitle != null) return _customVideoTitle!;
    if (_selectedVideoIndex != null) {
      return _sampleVideos[_selectedVideoIndex!]['title']!;
    }
    return '';
  }

  String get _currentDuration {
    if (_customDuration != null) return _customDuration!;
    if (_selectedVideoIndex != null) {
      return _sampleVideos[_selectedVideoIndex!]['duration']!;
    }
    return '';
  }

  String get _currentSpecs {
    if (_customSpecs != null) return _customSpecs!;
    if (_selectedVideoIndex != null) {
      return _sampleVideos[_selectedVideoIndex!]['specs']!;
    }
    return '';
  }

  String get _currentImage {
    if (_customImagePath != null) return _customImagePath!;
    if (_selectedVideoIndex != null) {
      return _sampleVideos[_selectedVideoIndex!]['image']!;
    }
    return 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80';
  }

  Future<void> _pickDeviceVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);
        setState(() {
          _selectedVideoIndex = null;
          _customVideoTitle = file.name;
          _customDuration = '02:30';
          _customSpecs = '$sizeMb MB • Device Gallery';
          _customImagePath =
              'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80';
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
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

              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR CHOOSE SAMPLE VIDEO',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.borderSubtle)),
                ],
              ),
              const SizedBox(height: 12),

              ...List.generate(_sampleVideos.length, (index) {
                final vid = _sampleVideos[index];
                final isSelected =
                    _selectedVideoIndex == index && _customVideoTitle == null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.borderSubtle,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primaryContainer.withOpacity(0.12)
                        : AppColors.surfaceContainer,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(vid['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      vid['title']!,
                      style: AppTypography.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${vid['duration']} • ${vid['specs']}',
                      style: AppTypography.bodySm,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _customVideoTitle = null;
                        _selectedVideoIndex = index;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
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

          const SizedBox(height: 20),

          // 3. Audio Tuning Controls Accordion
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _showAdvancedTuning = !_showAdvancedTuning;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Audio Tuning & Lip-Sync Controls',
                            style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _showAdvancedTuning
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                if (_showAdvancedTuning) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 16),

                  // Pitch Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Voice Pitch Offset', style: AppTypography.labelMd),
                      Text(
                        '${state.pitchHz > 0 ? "+${state.pitchHz.toInt()}" : state.pitchHz.toInt()} Hz ${state.pitchHz == 0 ? "(Standard)" : ""}',
                        style: AppTypography.codeMono,
                      ),
                    ],
                  ),
                  Slider(
                    value: state.pitchHz,
                    min: -10,
                    max: 10,
                    divisions: 20,
                    onChanged: (val) => state.setPitch(val),
                  ),

                  // Speed Multiplier Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Speech Speed & Cadence',
                          style: AppTypography.labelMd),
                      Text(
                        '${state.speedMultiplier.toStringAsFixed(2)}x ${state.speedMultiplier == 1.05 ? "(Auto-Align)" : ""}',
                        style: AppTypography.codeMono,
                      ),
                    ],
                  ),
                  Slider(
                    value: state.speedMultiplier,
                    min: 0.8,
                    max: 1.4,
                    divisions: 12,
                    onChanged: (val) => state.setSpeed(val),
                  ),

                  // Audio Ducking Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Background Audio Ducking',
                          style: AppTypography.labelMd),
                      Text(
                        '${state.duckingPercent.toInt()}% (Dialog Clear)',
                        style: AppTypography.codeMono,
                      ),
                    ],
                  ),
                  Slider(
                    value: state.duckingPercent,
                    min: -50,
                    max: -10,
                    divisions: 8,
                    onChanged: (val) => state.setDucking(val),
                  ),

                  // Reset defaults
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => state.resetTuning(),
                      icon: const Icon(Icons.refresh_rounded,
                          size: 14, color: AppColors.primary),
                      label: Text(
                        'Reset Defaults',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Primary CTA: "Start AI Khmer Dubbing"
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _hasSelectedVideo
                  ? AppColors.primaryGradient
                  : LinearGradient(
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
                onTap: () {
                  if (!_hasSelectedVideo) {
                    _showVideoSelectorModal();
                    return;
                  }

                  state.startNewDubbingJob(
                    videoTitle: _currentVideoTitle,
                    duration: _currentDuration,
                    fileSpecs: _currentSpecs,
                  );
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
                              'Dubbing pipeline started for $_currentVideoTitle!',
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

  /// Builds the Video Viewport (Empty State OR Selected Video Viewport)
  Widget _buildVideoViewport() {
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
                      'Tap to browse device gallery or choose sample files',
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
                  // Background Video Still
                  Positioned.fill(
                    child: Image.network(
                      _currentImage,
                      fit: BoxFit.cover,
                    ),
                  ),

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
                            '1080p • 60 FPS',
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
                                _currentDuration,
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

                  // Center Play Button
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isPlayingPreview = !_isPlayingPreview;
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 50,
                          height: 50,
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
                          child: Center(
                            child: Icon(
                              _isPlayingPreview
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
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
                                _currentVideoTitle,
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
                                      _currentSpecs,
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
