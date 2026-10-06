import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_l10n.dart';
import '../models/dub_models.dart';
import '../services/app_state.dart';
import '../services/chunking/video_chunking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class VideoChunkScreen extends StatefulWidget {
  final AppState state;

  const VideoChunkScreen({super.key, required this.state});

  @override
  State<VideoChunkScreen> createState() => _VideoChunkScreenState();
}

class _VideoChunkScreenState extends State<VideoChunkScreen> {
  VideoAsset? _videoAsset;
  VideoPlayerController? _videoController;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusLog = '';
  List<String>? _resultChunks;
  bool _isPlaying = false;
  Timer? _progressTimer;

  // Per-chunk playback state
  Map<String, VideoPlayerController?> _chunkPlayers = {};
  Set<String> _playingChunks = {};
  Map<String, VoidCallback> _chunkListeners = {};

  bool get _hasVideo => _videoAsset != null;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (widget.state.currentTabIndex != 4 && _isPlaying) {
      _pauseVid();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    widget.state.removeListener(_handleTabChange);
    _videoController?.removeListener(_onCtrlUpdate);
    _videoController?.dispose();
    // Dispose all chunk players and their listeners
    for (final entry in _chunkListeners.entries) {
      final player = _chunkPlayers[entry.key];
      if (player != null) {
        player.removeListener(entry.value);
        player.dispose();
      }
    }
    _chunkPlayers.clear();
    _chunkListeners.clear();
    super.dispose();
  }

  Future<void> _pauseVid() async {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    await c.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _playVid() async {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    await c.seekTo(Duration.zero);
    await c.play();
    if (!mounted) return;
    setState(() => _isPlaying = true);
  }

  void _onCtrlUpdate() {
    final v = _videoController!.value;
    if (_isPlaying != v.isPlaying) {
      setState(() => _isPlaying = v.isPlaying);
    } else if (v.isCompleted && _isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  void _onChunkCtrlUpdate(String chunkPath) {
    final player = _chunkPlayers[chunkPath];
    if (player == null) return;
    final v = player.value;
    if (v.isInitialized) {
      final isPlaying = player.value.isPlaying;
      setState(() {
        if (isPlaying) {
          _playingChunks.add(chunkPath);
        } else {
          _playingChunks.remove(chunkPath);
        }
      });
    }
  }

  Future<void> _playChunk(String path) async {
    // Stop current playback first
    for (final otherPath in _playingChunks.toList()) {
      if (otherPath != path) {
        final otherPlayer = _chunkPlayers[otherPath];
        if (otherPlayer != null) {
          await otherPlayer.pause();
        }
      }
    }

    var player = _chunkPlayers[path];
    if (player == null || !player.value.isInitialized) {
      try {
        final c = VideoPlayerController.file(File(path));
        await c.initialize();
        await c.setLooping(false);
        final listener = () => _onChunkCtrlUpdate(path);
        c.addListener(listener);
        _chunkListeners[path] = listener;
        player = c;
        _chunkPlayers[path] = player;
      } catch (e) {
        debugPrint('Chunk play error: $e');
        return;
      }
    }

    final p = _chunkPlayers[path];
    if (p == null) return;
    if (p.value.isPlaying) {
      await p.pause();
      setState(() => _playingChunks.remove(path));
    } else {
      await p.seekTo(Duration.zero);
      await p.play();
      setState(() => _playingChunks.add(path));
    }
  }

  Future<void> _clearAllResults() async {
    // Dispose all chunk players and their listeners
    for (final entry in _chunkListeners.entries) {
      final player = _chunkPlayers[entry.key];
      if (player != null) {
        player.removeListener(entry.value);
        await player.dispose();
      }
    }
    _chunkPlayers.clear();
    _chunkListeners.clear();
    _playingChunks.clear();
    setState(() {
      _resultChunks = null;
    });
  }

  Future<void> _pickVideo() async {
    try {
      final r = await FilePicker.platform
          .pickFiles(type: FileType.video, allowMultiple: false);
      if (r == null || r.files.isEmpty) return;
      final p = r.files.first.path;
      if (p == null || p.isEmpty) {
        _err('Cannot read video');
        return;
      }
      await _loadVideo(p);
    } catch (e) {
      debugPrint('Error: $e');
      _err('Could not load video.');
    }
  }

  Future<void> _loadVideo(String path) async {
    final prev = _videoController;
    _videoController = null;
    if (mounted) setState(() => _isPlaying = false);
    VideoPlayerController? ctrl;
    try {
      ctrl = VideoPlayerController.file(File(path));
      await ctrl.initialize();
      await ctrl.setLooping(false);
      await ctrl.seekTo(Duration.zero);
      final sz = ctrl.value.size;
      _videoAsset = VideoAsset(
        filePath: path,
        fileName: _name(path),
        duration: ctrl.value.duration,
        width: sz.width.toInt(),
        height: sz.height.toInt(),
        sizeBytes: await File(path).length(),
      );
    } catch (e) {
      debugPrint('Load error: $e');
      _err('Could not load video.');
    }
    prev?.removeListener(_onCtrlUpdate);
    prev?.dispose();
    if (mounted) {
      setState(() {
        _videoController = ctrl;
        _videoController?.addListener(_onCtrlUpdate);
      });
    }
  }

  static String _name(String p) => p.split('/').last.split('\\').last;

  void _err(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m,
            style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
        backgroundColor: AppColors.surfaceContainerHighest,
      ),
    );
  }

  Future<void> _startChunk() async {
    if (_isProcessing || !_hasVideo) return;
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _statusLog = '';
      _resultChunks = null;
    });

    // Create Videos/Chunks/<video name>/ output directory in app documents dir
    final docsDir = await getApplicationDocumentsDirectory();
    final videoName = _videoAsset!.fileName.split('.').first;
    final outputDir = '${docsDir.path}/Videos/Chunks/$videoName';
    final svc = VideoChunkingService();

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (tick) {
      if (!mounted || !_isProcessing) {
        _progressTimer?.cancel();
        _progressTimer = null;
        return;
      }
      setState(() {
        _progress = svc.progress;
        _statusLog = svc.statusLog;
      });
    });

    try {
      final res = await svc.chunkVideo(
        videoPath: _videoAsset!.filePath,
        outputDir: outputDir,
        videoName: videoName,
        onCancelled: () {},
      );
      _progressTimer?.cancel();
      _progressTimer = null;

      if (!mounted || svc.isCancelled) return;
      setState(() {
        _resultChunks = res.chunkPaths;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).chunkComplete} ${res.chunkPaths.length} chunks created • Saved to Gallery',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
            backgroundColor: AppColors.surfaceContainerLowest,
          ),
        );
      }
    } catch (e) {
      _progressTimer?.cancel();
      _progressTimer = null;
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _err(e.toString());
    }
  }

  Widget _buildEmpty(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
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
                child: Icon(Icons.video_settings_rounded,
                    color: AppColors.primary, size: 26)),
          ),
          const SizedBox(height: 14),
          Text(l10n.chunkEmptyTitle,
              style: AppTypography.headlineSm
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l10n.chunkEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: Text(l10n.chunkSelectVideo,
                  style: AppTypography.labelMd
                      .copyWith(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext ctx) {
    final a = _videoAsset!;
    final fmt =
        VideoChunkingService.formatTime(a.duration.inSeconds.toDouble());
    final c = _videoController;
    final rd = c != null && c.value.isInitialized;
    final ar = rd ? c!.value.aspectRatio : 16 / 9;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Stack(alignment: Alignment.center, children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12)),
                    child: rd
                        ? Center(
                            child: AspectRatio(
                                aspectRatio: ar, child: VideoPlayer(c)))
                        : null,
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.85),
                  child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.fileName,
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(fmt,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: AppLocalizations.of(ctx).replaceButton,
                  onPressed: _isProcessing ? null : _pickVideo,
                ),
                const SizedBox(width: 8),
                // Optional spacing between icon and button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _startChunk,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(
                      _isProcessing
                          ? AppLocalizations.of(ctx).chunkProcessing
                          : AppLocalizations.of(ctx).chunkStartButton,
                      style: AppTypography.labelMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? AppColors.primary.withOpacity(0.7)
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      // Properly constrained by Expanded
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: AppColors.surfaceContainerLowest,
                child: FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary])),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(_statusLog,
                style: AppTypography.codeMono
                    .copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ],
        ]),
      ),
    );
  }

  Widget _buildResults(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tertiary.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.tertiary, size: 20),
            const SizedBox(width: 8),
            Text(l10n.chunkComplete,
                style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.tertiary))
          ]),
          const SizedBox(height: 4),
          Text('${_resultChunks!.length} ${l10n.chunkChunksCreated}',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          // Chunks saved to Gallery confirmation
          Row(children: [
            const Icon(Icons.cloud_done_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            Text(
                'Saved to Gallery (Movies/${_videoAsset!.fileName.split('.').first}/)',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.secondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
          ]),
          const SizedBox(height: 12),
          // Clear/Reset button
          OutlinedButton.icon(
            onPressed: _clearAllResults,
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: Text(l10n.chunkClearAll,
                style: AppTypography.labelMd
                    .copyWith(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              side: BorderSide(color: AppColors.outline.withOpacity(0.4)),
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      ..._resultChunks!.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              iconColor: AppColors.primary,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: const Icon(Icons.video_file_rounded,
                  color: AppColors.primary, size: 20),
              title: Text(p.split('/').last,
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(_fmtSize(File(p).lengthSync()),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              trailing: IconButton(
                icon: Icon(
                  _playingChunks.contains(p)
                      ? Icons.stop_rounded
                      : Icons.play_circle_outline_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
                tooltip: _playingChunks.contains(p) ? 'Stop' : 'Play',
                onPressed: () => _playChunk(p),
              ),
            ),
          )),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => setState(() => _resultChunks = null),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(l10n.chunkClose,
              style:
                  AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  String _fmtSize(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _togglePlay() async {
    if (_isPlaying)
      await _pauseVid();
    else
      await _playVid();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_resultChunks == null && !_isProcessing && !_hasVideo)
          _buildEmpty(context),
        if (_hasVideo && _resultChunks == null) ...[_buildInfoCard(context)],
        if (_resultChunks != null) ...[_buildResults(context)],
      ]),
    );
  }
}
