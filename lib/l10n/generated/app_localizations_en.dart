// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CineDub AI';

  @override
  String get appTagline => 'Khmer Engine';

  @override
  String get tabDub => 'Dub';

  @override
  String get tabQueue => 'Queue';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tabChunking => 'Chunk';

  @override
  String get screenHomeTitle => 'CineDub AI';

  @override
  String get screenHomeSubtitle => 'Khmer Engine';

  @override
  String get screenQueueTitle => 'Dubbing Queue';

  @override
  String get screenQueueSubtitle => 'Pipeline Monitor';

  @override
  String get screenPlayerTitle => 'Completed Dub';

  @override
  String get screenPlayerSubtitle => 'Studio Player';

  @override
  String get screenSettingsTitle => 'Dubbing Settings';

  @override
  String get screenSettingsSubtitle => 'Gemini & TTS Config';

  @override
  String get screenChunkingTitle => 'Video Chunking';

  @override
  String get screenChunkingSubtitle => 'AI-Powered Splitter';

  @override
  String get back => 'Back';

  @override
  String get languageSectionTitle => 'App Language / ភាសា';

  @override
  String get languageSectionSubtitle =>
      'Choose the language used across the whole app. The change applies immediately.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get languageSwitchedToEnglish => 'App language set to English.';

  @override
  String get languageSwitchedToKhmer => 'App language set to Khmer.';

  @override
  String get keysPoolTitle => 'Gemini API Keys Pool';

  @override
  String get keysPoolSubtitle =>
      'Add multiple keys to bypass RPM/TPM restrictions. CineDub AI auto-rotates active tokens during full-length Khmer cinematic dubbing pipelines.';

  @override
  String get registeredKeys => 'Registered Keys';

  @override
  String configuredCount(int count) {
    return '$count Configured';
  }

  @override
  String get addGeminiApiKey => 'Add Gemini API Key';

  @override
  String get keyAliasLabel => 'Key Alias / Description';

  @override
  String get keyAliasHint => 'e.g. Project Cinema Beta';

  @override
  String get geminiSecretTokenLabel => 'Gemini API Secret Token';

  @override
  String get tokenHint => 'AIzaSy...';

  @override
  String get addApiKeyButton => 'Add API Key';

  @override
  String get invalidTokenMessage => 'Please enter a valid Gemini API token.';

  @override
  String get apiKeySavedMessage => 'Gemini API key saved!';

  @override
  String get copyMaskedTokenTooltip => 'Copy Masked Token';

  @override
  String get deleteKeyTooltip => 'Delete Key';

  @override
  String copiedTokenMessage(String token) {
    return 'Copied $token to clipboard!';
  }

  @override
  String rpmUsageLabel(int used, int max, int percent) {
    return 'RPM: $used/$max ($percent%)';
  }

  @override
  String latencyMsLabel(int ms) {
    return '${ms}ms';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusStandby => 'Standby';

  @override
  String get statusCooldown => 'Cooldown';

  @override
  String get translationSectionTitle => 'TRANSLATION ENGINE & MODEL';

  @override
  String get defaultGeminiModel => 'Default Gemini Model';

  @override
  String get khmerToneStyle => 'Khmer Dubbing Tone & Style';

  @override
  String get keyRotationStrategy => 'Key Rotation Strategy';

  @override
  String get selectSourceVideo => 'Select Source Video';

  @override
  String get chooseFromGalleryOrFile => 'Choose from Gallery or File';

  @override
  String get selectVideoHint =>
      'Select MP4, MOV, or MKV video file from your device';

  @override
  String get selectVoiceMode => 'Select Voice Mode';

  @override
  String get voiceModeHint =>
      'Single Choice • Multi-Speaker Cast or Solo Voice';

  @override
  String get audioTuningSection => 'Audio Tuning & Lip-Sync Controls';

  @override
  String get voicePitchOffset => 'Voice Pitch Offset';

  @override
  String get speechSpeed => 'Speech Speed & Cadence';

  @override
  String get backgroundDucking => 'Background Audio Ducking';

  @override
  String get resetDefaults => 'Reset Defaults';

  @override
  String get startDubbingButton => 'Start AI Khmer Dubbing';

  @override
  String get pipelineEstimate => '4-Stage Compute • Est. time: ~1m 20s';

  @override
  String get clickToSelectSource => 'Click to select source video first';

  @override
  String get preparingPreview => 'Preparing video preview…';

  @override
  String get clickToSelectVideo => 'Click to select video from gallery or file';

  @override
  String get tapToPickVideo =>
      'Tap to pick a video file from your device storage';

  @override
  String get replaceButton => 'Replace';

  @override
  String get unableToReadVideo => 'Unable to read the selected video file.';

  @override
  String errorPickingFile(String error) {
    return 'Error picking file: $error';
  }

  @override
  String get couldNotLoadVideo => 'Could not load the selected video file.';

  @override
  String errorLoadingVideo(String error) {
    return 'Error loading video: $error';
  }

  @override
  String get videoPreviewFailed => 'Could not load this video for preview.';

  @override
  String errorReleasingPreview(String error) {
    return 'Error releasing video preview: $error';
  }

  @override
  String pipelineStartedFor(String video) {
    return 'Started dubbing pipeline for $video!';
  }

  @override
  String get terminateDialogTitle => 'Terminate Process?';

  @override
  String get terminateDialogBody =>
      'Are you sure you want to stop the ongoing translation and TTS synthesis? This will abort the current video render.';

  @override
  String get terminateConfirm => 'Terminate';

  @override
  String get terminateTooltip => 'Terminate Process';

  @override
  String get terminateFailedMessage => 'Dubbing process terminated.';

  @override
  String get removeDialogTitle => 'Remove from queue?';

  @override
  String removeDialogBody(String title) {
    return 'Remove \"$title\" from the queue? This video has not started processing yet, so nothing will be rendered for it.';
  }

  @override
  String get removeConfirm => 'Remove';

  @override
  String removedFromQueueMessage(String title) {
    return '\"$title\" removed from queue. This job is no longer in the queue.';
  }

  @override
  String removedListedMessage(String title) {
    return '\"$title\" removed from the queue. This job is no longer listed.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get emptyQueueTitle => 'No dubbing jobs yet';

  @override
  String get emptyQueueBodyLead =>
      'Pick a video and a voice on the Dub screen, then tap ';

  @override
  String get emptyQueueBodyTail =>
      '\"Start AI Khmer Dubbing\" to begin processing.';

  @override
  String get queueTitle => 'Dubbing Queue';

  @override
  String get queueSubtitle => 'Automated Khmer video pipeline monitor';

  @override
  String get syncLive => 'SYNC LIVE';

  @override
  String get stageProgression => 'Stage Progression';

  @override
  String get failedJobsSection => 'FAILED JOBS';

  @override
  String get failedJobsBodyLead =>
      'These renders stopped on an error. Stages before the failure are ';

  @override
  String get failedJobsBodyTail =>
      'marked completed; everything after it did not run.';

  @override
  String failedStageBadge(int stage) {
    return 'FAILED • STAGE $stage';
  }

  @override
  String get queuedVideosSection => 'QUEUED VIDEOS';

  @override
  String queuedBadge(int position) {
    return 'QUEUED #$position';
  }

  @override
  String get awaitingSlot =>
      'Awaiting worker slot • Will execute after active render';

  @override
  String get removeFromQueueTooltip => 'Remove from queue';

  @override
  String get recentlyCompletedSection => 'RECENTLY COMPLETED';

  @override
  String get playButton => 'Play';

  @override
  String get emptyPlayerTitle => 'No dubbed video yet';

  @override
  String get emptyPlayerBodyLead =>
      'Finish a job in the Queue, then tap \"Play\" on it to watch the ';

  @override
  String get emptyPlayerBodyTail => 'rendered Khmer dub here.';

  @override
  String voiceLabel(String name) {
    return 'Voice: $name';
  }

  @override
  String playbackLabel(String current, String total) {
    return 'Playback $current / $total';
  }

  @override
  String get saveToGalleryButton => 'Save to Gallery';

  @override
  String get savingToGallery => 'Saving…';

  @override
  String get savedToGallery => 'Saved to Gallery';

  @override
  String get retrySaveToGallery => 'Retry Save to Gallery';

  @override
  String get noRenderedVideoYet => 'This job has no rendered video file yet.';

  @override
  String renderedVideoMissing(String path) {
    return 'The rendered video no longer exists on disk:\n$path';
  }

  @override
  String couldNotOpenVideo(String error) {
    return 'Could not open this video:\n$error';
  }

  @override
  String get retryThisStage => 'Retry this stage';

  @override
  String pipelineErrorIn(String stage) {
    return 'Pipeline error in $stage';
  }

  @override
  String get rawErrorMessage => 'Raw error message';

  @override
  String get noDetailsCaptured => '(no details captured)';

  @override
  String get copyErrorReport => 'Copy error report';

  @override
  String get errorReportCopied => 'Error report copied to clipboard';

  @override
  String couldNotCopyError(String error) {
    return 'Could not copy to clipboard: $error';
  }

  @override
  String get licensePrompt => 'Enter your license key to continue.';

  @override
  String get activateTitle => 'Activate CineDub AI';

  @override
  String get activateBody =>
      'Enter the license key you received to activate this device.';

  @override
  String get licenseKeyLabel => 'License key';

  @override
  String get licenseKeyHint => 'KD-XXXX-XXXX-XXXX';

  @override
  String get activateButton => 'Activate';

  @override
  String get stageTitle1 => '1. Extract audio';

  @override
  String get stageTitle2 => '2. Transcribe and translate';

  @override
  String get stageTitle3 => '3. Generate voice';

  @override
  String get stageTitle4 => '4. Build video';

  @override
  String stageFallback(int index) {
    return 'Stage $index';
  }

  @override
  String get badgeFailed => 'Failed';

  @override
  String get badgeCompleted => 'Completed';

  @override
  String get badgeInProgress => 'In Progress';

  @override
  String get badgeNextUp => 'Next Up';

  @override
  String get badgePending => 'Pending';

  @override
  String get failedDesc0 => 'Audio extraction failed';

  @override
  String get failedDesc1 => 'Transcription / translation failed';

  @override
  String get failedDesc2 => 'Speech synthesis failed';

  @override
  String get failedDesc3 => 'Video render failed';

  @override
  String get stage0Done => 'Demuxed 48kHz WAV audio stream';

  @override
  String get stage0Running => 'Demuxing audio track to 48kHz WAV';

  @override
  String get stage0Pending => 'Awaiting audio extraction';

  @override
  String get stage1Done => 'Khmer translation completed';

  @override
  String get stage1Running => 'Translating dialogue to Khmer';

  @override
  String get stage1Pending => 'Khmer translation queued';

  @override
  String get stage2Done => 'Edge-TTS Khmer audio rendered';

  @override
  String get stage2Running => 'Synthesizing...';

  @override
  String get stage2Pending => 'Synthesis queued';

  @override
  String get stage3Done => 'Final dubbed MP4 rendered';

  @override
  String get stage3Running => 'Remuxing video & muxing Khmer audio';

  @override
  String get stage3Pending => 'Video remux & lip-sync pending';

  @override
  String preparingPipeline(String title) {
    return 'Preparing pipeline for $title';
  }

  @override
  String waitingInQueue(int position) {
    return 'Waiting in queue position #$position';
  }

  @override
  String startingPipeline(String title) {
    return 'Starting pipeline for $title';
  }

  @override
  String get allStagesCompleted => 'All 4 stages completed • Output ready';

  @override
  String queuedToRetry(String stage) {
    return 'Queued to retry from $stage';
  }

  @override
  String stoppedAtStage(String stage, String message) {
    return 'Stopped at $stage • $message';
  }

  @override
  String get selectVideoSourceTitle => 'Select Video Source';

  @override
  String get galleryOption => 'From Gallery';

  @override
  String get fileOption => 'From File';

  @override
  String get couldNotReadVideo => 'Could not read the selected video file.';

  @override
  String get advancedAudioTuning => 'Advanced Audio Tuning';

  @override
  String get noVoiceSelected => 'None selected';

  @override
  String get terminateProcessTitle => 'Terminate Process?';

  @override
  String get terminateProcessBody =>
      'Are you sure you want to stop the ongoing translation and TTS synthesis? This will abort the current video render.';

  @override
  String get processTerminated => 'Dubbing process terminated.';

  @override
  String get removeFromQueueTitle => 'Remove from queue?';

  @override
  String removeFromQueueBody(Object title) {
    return 'Remove \"$title\" from the queue? This video has not started processing yet, so nothing will be rendered for it.';
  }

  @override
  String removedFromQueue(Object title) {
    return '\"$title\" removed from queue.';
  }

  @override
  String get jobNoLongerInQueue => 'This job is no longer in the queue.';

  @override
  String get processingActiveTask => 'Processing';

  @override
  String get completedRecentJobs => 'Recently Completed';

  @override
  String get failedJobs => 'Failed Jobs';

  @override
  String get liveBadge => 'Live';

  @override
  String get emptyStateEmptyQueue => 'No dubbing jobs yet';

  @override
  String get emptyStateEmptyQueueBody =>
      'Pick a video and a voice on the Dub screen, then tap \"Start AI Khmer Dubbing\" to begin processing.';

  @override
  String get emptyStateEmptyPlayer => 'No dubbed video yet';

  @override
  String get emptyStateEmptyPlayerBody =>
      'Finish a job in the Queue, then tap \"Play\" on it to watch the rendered Khmer dub here.';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get savingLabel => 'Saving…';

  @override
  String get savedLabel => 'Saved to Gallery';

  @override
  String get retrySaveToGalleryLabel => 'Retry Save to Gallery';

  @override
  String get loadErrorUnknown =>
      'Something went wrong while opening this video.';

  @override
  String get copyFullReport => 'Copy full report';

  @override
  String get reportCopied => 'Report copied to clipboard';

  @override
  String get pipelineError => 'Pipeline error';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get selectVoiceModeTitle => 'Select Voice Mode';

  @override
  String get chunkEmptyTitle => 'No video selected';

  @override
  String get chunkEmptyBody =>
      'Pick a video file to split it into 7-minute chunks using AI silence detection.';

  @override
  String get chunkSelectVideo => 'Select Video';

  @override
  String get chunkStartButton => 'Start AI Chunking';

  @override
  String get chunkProcessing => 'AI is processing...';

  @override
  String get chunkExtractingAudio => 'Extracting audio...';

  @override
  String get chunkDetectingSilence => 'Detecting silence gaps...';

  @override
  String get chunkFindingCutPoint => 'Finding optimal cut point...';

  @override
  String get chunkCuttingVideo => 'Splitting video...';

  @override
  String get chunkComplete => 'Chunking complete!';

  @override
  String chunkChunksCreated(Object count) {
    return '$count chunks created';
  }

  @override
  String get chunkClose => 'Close';

  @override
  String get chunkError => 'Chunking failed';

  @override
  String get chunkRestart => 'Restart';

  @override
  String get chunkClearAll => 'Clear All';

  @override
  String get chunkSaveToGallery => 'Save to Gallery';

  @override
  String get playVideo => 'Play';
}
