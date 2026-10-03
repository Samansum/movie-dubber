import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/animated_waveform.dart';
import '../widgets/glass_card.dart';

class CompletedPlayerScreen extends StatelessWidget {
  final AppState state;

  const CompletedPlayerScreen({
    super.key,
    required this.state,
  });

  String _formatDuration(double seconds) {
    int totalSec = seconds.toInt();
    int m = totalSec ~/ 60;
    int s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status & Quality Telemetry Banner
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.tertiary,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rendering & Sync Complete',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(state.totalVideoDurationSeconds),
                      style: AppTypography.codeMono.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SciFi_Neon_Scene_Dubbed.mp4',
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '1080p 60fps • 48kHz • 54.2 MB',
                      style: AppTypography.codeMono.copyWith(
                        color: AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Cinematic 16:9 Video Player Viewport
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        // Cyberpunk video render still
                        Positioned.fill(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=800&auto=format&fit=crop&q=80',
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Top Scrim Gradient
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xCC000000), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
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
                                        state.isKhmerAudioTrack
                                            ? 'AI DUBBED • KHMER'
                                            : 'ORIGINAL ENGLISH',
                                        style: AppTypography.labelSm.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'REC ${_formatDuration(state.playbackSeconds)}',
                                    style: AppTypography.codeMono.copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Play / Pause Floating Trigger
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => state.togglePlayVideo(),
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
                                child: Center(
                                  child: Icon(
                                    state.isPlayingVideo
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Dynamic Live Subtitles Render Layer
                        if (state.isSubtitleEnabled)
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '«យើងបានបញ្ចប់បេសកកម្មដោយជោគជ័យ!»',
                                      style: AppTypography.headlineSm.copyWith(
                                        fontSize: 14,
                                        color: AppColors.secondaryFixed,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '[Mission completed successfully!]',
                                      style: AppTypography.bodySm.copyWith(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Player Timeline & Audio Scrubber
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(state.playbackSeconds),
                              style: AppTypography.codeMono.copyWith(fontSize: 12),
                            ),
                            Text(
                              _formatDuration(state.totalVideoDurationSeconds),
                              style: AppTypography.codeMono.copyWith(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: state.playbackSeconds,
                          min: 0,
                          max: state.totalVideoDurationSeconds,
                          onChanged: (val) => state.seekVideo(val),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Subtitle Toggle
                            InkWell(
                              onTap: () => state.toggleSubtitle(),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: state.isSubtitleEnabled
                                      ? AppColors.primaryContainer.withOpacity(0.25)
                                      : AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: state.isSubtitleEnabled
                                        ? AppColors.primary
                                        : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.subtitles_rounded,
                                      size: 14,
                                      color: state.isSubtitleEnabled
                                          ? AppColors.primary
                                          : AppColors.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.isSubtitleEnabled ? 'KM SUB' : 'SUB OFF',
                                      style: AppTypography.labelSm.copyWith(
                                        color: state.isSubtitleEnabled
                                            ? AppColors.primary
                                            : AppColors.outline,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Audio Track Switcher (Khmer vs Original)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => state.setAudioTrack(true),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: state.isKhmerAudioTrack
                                            ? AppColors.primaryContainer
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Khmer AI',
                                        style: AppTypography.labelSm.copyWith(
                                          color: state.isKhmerAudioTrack
                                              ? Colors.white
                                              : AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => state.setAudioTrack(false),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: !state.isKhmerAudioTrack
                                            ? AppColors.secondaryContainer
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Original',
                                        style: AppTypography.labelSm.copyWith(
                                          color: !state.isKhmerAudioTrack
                                              ? Colors.white
                                              : AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Dialogue Snippets / Lip-Sync QC Check
          Text(
            'LIP-SYNC & DIALOGUE SEGMENTS',
            style: AppTypography.labelSm.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildDialogueRow(
                  timestamp: '00:12',
                  enText: 'We have reached the grid boundary.',
                  kmText: 'យើងបានមកដល់ព្រំដែនប្រព័ន្ធហើយ។',
                  voice: 'Piseth Neural',
                  isCurrent: true,
                ),
                const Divider(color: AppColors.borderSubtle, height: 16),
                _buildDialogueRow(
                  timestamp: '00:34',
                  enText: 'Target confirmed. Initiating link.',
                  kmText: 'ផ្ទៀងផ្ទាត់គោលដៅរួចរាល់។ ចាប់ផ្តើមតភ្ជាប់។',
                  voice: 'Piseth Neural',
                  isCurrent: false,
                ),
                const Divider(color: AppColors.borderSubtle, height: 16),
                _buildDialogueRow(
                  timestamp: '01:14',
                  enText: 'Mission completed successfully!',
                  kmText: 'យើងបានបញ្ចប់បេសកកម្មដោយជោគជ័យ!',
                  voice: 'Piseth Neural',
                  isCurrent: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Primary Save to Gallery Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: state.saveGalleryState == 'saved'
                  ? const LinearGradient(colors: [Color(0xFF007650), Color(0xFF10B981)])
                  : const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF732EE4)]),
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
                onTap: state.saveGalleryState == 'saving'
                    ? null
                    : () {
                        state.saveToGallery(() {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.tertiaryContainer,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Saved SciFi_Neon_Scene_Dubbed.mp4 to Photo Library!',
                                    style: AppTypography.bodyMd.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        });
                      },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.saveGalleryState == 'saving')
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else if (state.saveGalleryState == 'saved')
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24)
                      else
                        const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        state.saveGalleryState == 'saving'
                            ? 'Saving to /DCIM...'
                            : (state.saveGalleryState == 'saved'
                                ? 'Saved in Photo Library!'
                                : 'Save to Gallery'),
                        style: AppTypography.headlineSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '54MB',
                          style: AppTypography.codeMono.copyWith(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Utilities (Share & Re-dub)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    backgroundColor: AppColors.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        content: const Text('Export link copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share Video'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                    backgroundColor: AppColors.surfaceContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    state.setTabIndex(0); // Jump back to Dub screen
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('New Dub'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueRow({
    required String timestamp,
    required String enText,
    required String kmText,
    required String voice,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primaryContainer.withOpacity(0.3)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            timestamp,
            style: AppTypography.codeMono.copyWith(
              fontSize: 10,
              color: isCurrent ? AppColors.primary : AppColors.outline,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kmText,
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? AppColors.secondaryFixed : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                enText,
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
