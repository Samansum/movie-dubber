import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CineDub AI'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Khmer Engine'**
  String get appTagline;

  /// No description provided for @tabDub.
  ///
  /// In en, this message translates to:
  /// **'Dub'**
  String get tabDub;

  /// No description provided for @tabQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get tabQueue;

  /// No description provided for @tabPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get tabPlayer;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @tabChunking.
  ///
  /// In en, this message translates to:
  /// **'Chunk'**
  String get tabChunking;

  /// No description provided for @screenHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'CineDub AI'**
  String get screenHomeTitle;

  /// No description provided for @screenHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Khmer Engine'**
  String get screenHomeSubtitle;

  /// No description provided for @screenQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Dubbing Queue'**
  String get screenQueueTitle;

  /// No description provided for @screenQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pipeline Monitor'**
  String get screenQueueSubtitle;

  /// No description provided for @screenPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed Dub'**
  String get screenPlayerTitle;

  /// No description provided for @screenPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Studio Player'**
  String get screenPlayerSubtitle;

  /// No description provided for @screenSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dubbing Settings'**
  String get screenSettingsTitle;

  /// No description provided for @screenSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini & TTS Config'**
  String get screenSettingsSubtitle;

  /// No description provided for @screenChunkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Chunking'**
  String get screenChunkingTitle;

  /// No description provided for @screenChunkingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Splitter'**
  String get screenChunkingSubtitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language / ភាសា'**
  String get languageSectionTitle;

  /// No description provided for @languageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the whole app. The change applies immediately.'**
  String get languageSectionSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ'**
  String get languageKhmer;

  /// No description provided for @languageSwitchedToEnglish.
  ///
  /// In en, this message translates to:
  /// **'App language set to English.'**
  String get languageSwitchedToEnglish;

  /// No description provided for @languageSwitchedToKhmer.
  ///
  /// In en, this message translates to:
  /// **'App language set to Khmer.'**
  String get languageSwitchedToKhmer;

  /// No description provided for @keysPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Keys Pool'**
  String get keysPoolTitle;

  /// No description provided for @keysPoolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add multiple keys to bypass RPM/TPM restrictions. CineDub AI auto-rotates active tokens during full-length Khmer cinematic dubbing pipelines.'**
  String get keysPoolSubtitle;

  /// No description provided for @registeredKeys.
  ///
  /// In en, this message translates to:
  /// **'Registered Keys'**
  String get registeredKeys;

  /// Number of Gemini API keys currently stored.
  ///
  /// In en, this message translates to:
  /// **'{count} Configured'**
  String configuredCount(int count);

  /// No description provided for @addGeminiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add Gemini API Key'**
  String get addGeminiApiKey;

  /// No description provided for @keyAliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Alias / Description'**
  String get keyAliasLabel;

  /// No description provided for @keyAliasHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Project Cinema Beta'**
  String get keyAliasHint;

  /// No description provided for @geminiSecretTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Secret Token'**
  String get geminiSecretTokenLabel;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'AIzaSy...'**
  String get tokenHint;

  /// No description provided for @addApiKeyButton.
  ///
  /// In en, this message translates to:
  /// **'Add API Key'**
  String get addApiKeyButton;

  /// No description provided for @invalidTokenMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Gemini API token.'**
  String get invalidTokenMessage;

  /// No description provided for @apiKeySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key saved!'**
  String get apiKeySavedMessage;

  /// No description provided for @copyMaskedTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy Masked Token'**
  String get copyMaskedTokenTooltip;

  /// No description provided for @deleteKeyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Key'**
  String get deleteKeyTooltip;

  /// Snackbar shown after copying a masked API token.
  ///
  /// In en, this message translates to:
  /// **'Copied {token} to clipboard!'**
  String copiedTokenMessage(String token);

  /// Requests-per-minute usage for one API key.
  ///
  /// In en, this message translates to:
  /// **'RPM: {used}/{max} ({percent}%)'**
  String rpmUsageLabel(int used, int max, int percent);

  /// Measured API latency in milliseconds.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String latencyMsLabel(int ms);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusStandby.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get statusStandby;

  /// No description provided for @statusCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get statusCooldown;

  /// No description provided for @translationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION ENGINE & MODEL'**
  String get translationSectionTitle;

  /// No description provided for @defaultGeminiModel.
  ///
  /// In en, this message translates to:
  /// **'Default Gemini Model'**
  String get defaultGeminiModel;

  /// No description provided for @khmerToneStyle.
  ///
  /// In en, this message translates to:
  /// **'Khmer Dubbing Tone & Style'**
  String get khmerToneStyle;

  /// No description provided for @keyRotationStrategy.
  ///
  /// In en, this message translates to:
  /// **'Key Rotation Strategy'**
  String get keyRotationStrategy;

  /// No description provided for @selectSourceVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Source Video'**
  String get selectSourceVideo;

  /// No description provided for @chooseFromGalleryOrFile.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery or File'**
  String get chooseFromGalleryOrFile;

  /// No description provided for @selectVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Select MP4, MOV, or MKV video file from your device'**
  String get selectVideoHint;

  /// No description provided for @selectVoiceMode.
  ///
  /// In en, this message translates to:
  /// **'Select Voice Mode'**
  String get selectVoiceMode;

  /// No description provided for @voiceModeHint.
  ///
  /// In en, this message translates to:
  /// **'Single Choice • Multi-Speaker Cast or Solo Voice'**
  String get voiceModeHint;

  /// No description provided for @audioTuningSection.
  ///
  /// In en, this message translates to:
  /// **'Audio Tuning & Lip-Sync Controls'**
  String get audioTuningSection;

  /// No description provided for @voicePitchOffset.
  ///
  /// In en, this message translates to:
  /// **'Voice Pitch Offset'**
  String get voicePitchOffset;

  /// No description provided for @speechSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speech Speed & Cadence'**
  String get speechSpeed;

  /// No description provided for @backgroundDucking.
  ///
  /// In en, this message translates to:
  /// **'Background Audio Ducking'**
  String get backgroundDucking;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset Defaults'**
  String get resetDefaults;

  /// No description provided for @startDubbingButton.
  ///
  /// In en, this message translates to:
  /// **'Start AI Khmer Dubbing'**
  String get startDubbingButton;

  /// No description provided for @pipelineEstimate.
  ///
  /// In en, this message translates to:
  /// **'4-Stage Compute • Est. time: ~1m 20s'**
  String get pipelineEstimate;

  /// No description provided for @clickToSelectSource.
  ///
  /// In en, this message translates to:
  /// **'Click to select source video first'**
  String get clickToSelectSource;

  /// No description provided for @preparingPreview.
  ///
  /// In en, this message translates to:
  /// **'Preparing video preview…'**
  String get preparingPreview;

  /// No description provided for @clickToSelectVideo.
  ///
  /// In en, this message translates to:
  /// **'Click to select video from gallery or file'**
  String get clickToSelectVideo;

  /// No description provided for @tapToPickVideo.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick a video file from your device storage'**
  String get tapToPickVideo;

  /// No description provided for @replaceButton.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceButton;

  /// No description provided for @unableToReadVideo.
  ///
  /// In en, this message translates to:
  /// **'Unable to read the selected video file.'**
  String get unableToReadVideo;

  /// No description provided for @errorPickingFile.
  ///
  /// In en, this message translates to:
  /// **'Error picking file: {error}'**
  String errorPickingFile(String error);

  /// No description provided for @couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load the selected video file.'**
  String get couldNotLoadVideo;

  /// No description provided for @errorLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error loading video: {error}'**
  String errorLoadingVideo(String error);

  /// No description provided for @videoPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this video for preview.'**
  String get videoPreviewFailed;

  /// No description provided for @errorReleasingPreview.
  ///
  /// In en, this message translates to:
  /// **'Error releasing video preview: {error}'**
  String errorReleasingPreview(String error);

  /// No description provided for @pipelineStartedFor.
  ///
  /// In en, this message translates to:
  /// **'Started dubbing pipeline for {video}!'**
  String pipelineStartedFor(String video);

  /// No description provided for @terminateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate Process?'**
  String get terminateDialogTitle;

  /// No description provided for @terminateDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop the ongoing translation and TTS synthesis? This will abort the current video render.'**
  String get terminateDialogBody;

  /// No description provided for @terminateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminateConfirm;

  /// No description provided for @terminateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Terminate Process'**
  String get terminateTooltip;

  /// No description provided for @terminateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Dubbing process terminated.'**
  String get terminateFailedMessage;

  /// No description provided for @removeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue?'**
  String get removeDialogTitle;

  /// No description provided for @removeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from the queue? This video has not started processing yet, so nothing will be rendered for it.'**
  String removeDialogBody(String title);

  /// No description provided for @removeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeConfirm;

  /// No description provided for @removedFromQueueMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from queue. This job is no longer in the queue.'**
  String removedFromQueueMessage(String title);

  /// No description provided for @removedListedMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from the queue. This job is no longer listed.'**
  String removedListedMessage(String title);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @emptyQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'No dubbing jobs yet'**
  String get emptyQueueTitle;

  /// No description provided for @emptyQueueBodyLead.
  ///
  /// In en, this message translates to:
  /// **'Pick a video and a voice on the Dub screen, then tap '**
  String get emptyQueueBodyLead;

  /// No description provided for @emptyQueueBodyTail.
  ///
  /// In en, this message translates to:
  /// **'\"Start AI Khmer Dubbing\" to begin processing.'**
  String get emptyQueueBodyTail;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Dubbing Queue'**
  String get queueTitle;

  /// No description provided for @queueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automated Khmer video pipeline monitor'**
  String get queueSubtitle;

  /// No description provided for @syncLive.
  ///
  /// In en, this message translates to:
  /// **'SYNC LIVE'**
  String get syncLive;

  /// No description provided for @stageProgression.
  ///
  /// In en, this message translates to:
  /// **'Stage Progression'**
  String get stageProgression;

  /// No description provided for @failedJobsSection.
  ///
  /// In en, this message translates to:
  /// **'FAILED JOBS'**
  String get failedJobsSection;

  /// No description provided for @failedJobsBodyLead.
  ///
  /// In en, this message translates to:
  /// **'These renders stopped on an error. Stages before the failure are '**
  String get failedJobsBodyLead;

  /// No description provided for @failedJobsBodyTail.
  ///
  /// In en, this message translates to:
  /// **'marked completed; everything after it did not run.'**
  String get failedJobsBodyTail;

  /// No description provided for @failedStageBadge.
  ///
  /// In en, this message translates to:
  /// **'FAILED • STAGE {stage}'**
  String failedStageBadge(int stage);

  /// No description provided for @queuedVideosSection.
  ///
  /// In en, this message translates to:
  /// **'QUEUED VIDEOS'**
  String get queuedVideosSection;

  /// No description provided for @queuedBadge.
  ///
  /// In en, this message translates to:
  /// **'QUEUED #{position}'**
  String queuedBadge(int position);

  /// No description provided for @awaitingSlot.
  ///
  /// In en, this message translates to:
  /// **'Awaiting worker slot • Will execute after active render'**
  String get awaitingSlot;

  /// No description provided for @removeFromQueueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueueTooltip;

  /// No description provided for @recentlyCompletedSection.
  ///
  /// In en, this message translates to:
  /// **'RECENTLY COMPLETED'**
  String get recentlyCompletedSection;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @emptyPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'No dubbed video yet'**
  String get emptyPlayerTitle;

  /// No description provided for @emptyPlayerBodyLead.
  ///
  /// In en, this message translates to:
  /// **'Finish a job in the Queue, then tap \"Play\" on it to watch the '**
  String get emptyPlayerBodyLead;

  /// No description provided for @emptyPlayerBodyTail.
  ///
  /// In en, this message translates to:
  /// **'rendered Khmer dub here.'**
  String get emptyPlayerBodyTail;

  /// No description provided for @voiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice: {name}'**
  String voiceLabel(String name);

  /// No description provided for @playbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Playback {current} / {total}'**
  String playbackLabel(String current, String total);

  /// No description provided for @saveToGalleryButton.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGalleryButton;

  /// No description provided for @savingToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingToGallery;

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to Gallery'**
  String get savedToGallery;

  /// No description provided for @retrySaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Retry Save to Gallery'**
  String get retrySaveToGallery;

  /// No description provided for @noRenderedVideoYet.
  ///
  /// In en, this message translates to:
  /// **'This job has no rendered video file yet.'**
  String get noRenderedVideoYet;

  /// No description provided for @renderedVideoMissing.
  ///
  /// In en, this message translates to:
  /// **'The rendered video no longer exists on disk:\n{path}'**
  String renderedVideoMissing(String path);

  /// No description provided for @couldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open this video:\n{error}'**
  String couldNotOpenVideo(String error);

  /// No description provided for @retryThisStage.
  ///
  /// In en, this message translates to:
  /// **'Retry this stage'**
  String get retryThisStage;

  /// No description provided for @pipelineErrorIn.
  ///
  /// In en, this message translates to:
  /// **'Pipeline error in {stage}'**
  String pipelineErrorIn(String stage);

  /// No description provided for @rawErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Raw error message'**
  String get rawErrorMessage;

  /// No description provided for @noDetailsCaptured.
  ///
  /// In en, this message translates to:
  /// **'(no details captured)'**
  String get noDetailsCaptured;

  /// No description provided for @copyErrorReport.
  ///
  /// In en, this message translates to:
  /// **'Copy error report'**
  String get copyErrorReport;

  /// No description provided for @errorReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Error report copied to clipboard'**
  String get errorReportCopied;

  /// No description provided for @couldNotCopyError.
  ///
  /// In en, this message translates to:
  /// **'Could not copy to clipboard: {error}'**
  String couldNotCopyError(String error);

  /// No description provided for @licensePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your license key to continue.'**
  String get licensePrompt;

  /// No description provided for @activateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate CineDub AI'**
  String get activateTitle;

  /// No description provided for @activateBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the license key you received to activate this device.'**
  String get activateBody;

  /// No description provided for @licenseKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'License key'**
  String get licenseKeyLabel;

  /// No description provided for @licenseKeyHint.
  ///
  /// In en, this message translates to:
  /// **'KD-XXXX-XXXX-XXXX'**
  String get licenseKeyHint;

  /// No description provided for @activateButton.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateButton;

  /// No description provided for @stageTitle1.
  ///
  /// In en, this message translates to:
  /// **'1. Extract audio'**
  String get stageTitle1;

  /// No description provided for @stageTitle2.
  ///
  /// In en, this message translates to:
  /// **'2. Transcribe and translate'**
  String get stageTitle2;

  /// No description provided for @stageTitle3.
  ///
  /// In en, this message translates to:
  /// **'3. Generate voice'**
  String get stageTitle3;

  /// No description provided for @stageTitle4.
  ///
  /// In en, this message translates to:
  /// **'4. Build video'**
  String get stageTitle4;

  /// No description provided for @stageFallback.
  ///
  /// In en, this message translates to:
  /// **'Stage {index}'**
  String stageFallback(int index);

  /// No description provided for @badgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get badgeFailed;

  /// No description provided for @badgeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get badgeCompleted;

  /// No description provided for @badgeInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get badgeInProgress;

  /// No description provided for @badgeNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get badgeNextUp;

  /// No description provided for @badgePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get badgePending;

  /// No description provided for @failedDesc0.
  ///
  /// In en, this message translates to:
  /// **'Audio extraction failed'**
  String get failedDesc0;

  /// No description provided for @failedDesc1.
  ///
  /// In en, this message translates to:
  /// **'Transcription / translation failed'**
  String get failedDesc1;

  /// No description provided for @failedDesc2.
  ///
  /// In en, this message translates to:
  /// **'Speech synthesis failed'**
  String get failedDesc2;

  /// No description provided for @failedDesc3.
  ///
  /// In en, this message translates to:
  /// **'Video render failed'**
  String get failedDesc3;

  /// No description provided for @stage0Done.
  ///
  /// In en, this message translates to:
  /// **'Demuxed 48kHz WAV audio stream'**
  String get stage0Done;

  /// No description provided for @stage0Running.
  ///
  /// In en, this message translates to:
  /// **'Demuxing audio track to 48kHz WAV'**
  String get stage0Running;

  /// No description provided for @stage0Pending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting audio extraction'**
  String get stage0Pending;

  /// No description provided for @stage1Done.
  ///
  /// In en, this message translates to:
  /// **'Khmer translation completed'**
  String get stage1Done;

  /// No description provided for @stage1Running.
  ///
  /// In en, this message translates to:
  /// **'Translating dialogue to Khmer'**
  String get stage1Running;

  /// No description provided for @stage1Pending.
  ///
  /// In en, this message translates to:
  /// **'Khmer translation queued'**
  String get stage1Pending;

  /// No description provided for @stage2Done.
  ///
  /// In en, this message translates to:
  /// **'Edge-TTS Khmer audio rendered'**
  String get stage2Done;

  /// No description provided for @stage2Running.
  ///
  /// In en, this message translates to:
  /// **'Synthesizing...'**
  String get stage2Running;

  /// No description provided for @stage2Pending.
  ///
  /// In en, this message translates to:
  /// **'Synthesis queued'**
  String get stage2Pending;

  /// No description provided for @stage3Done.
  ///
  /// In en, this message translates to:
  /// **'Final dubbed MP4 rendered'**
  String get stage3Done;

  /// No description provided for @stage3Running.
  ///
  /// In en, this message translates to:
  /// **'Remuxing video & muxing Khmer audio'**
  String get stage3Running;

  /// No description provided for @stage3Pending.
  ///
  /// In en, this message translates to:
  /// **'Video remux & lip-sync pending'**
  String get stage3Pending;

  /// No description provided for @preparingPipeline.
  ///
  /// In en, this message translates to:
  /// **'Preparing pipeline for {title}'**
  String preparingPipeline(String title);

  /// No description provided for @waitingInQueue.
  ///
  /// In en, this message translates to:
  /// **'Waiting in queue position #{position}'**
  String waitingInQueue(int position);

  /// No description provided for @startingPipeline.
  ///
  /// In en, this message translates to:
  /// **'Starting pipeline for {title}'**
  String startingPipeline(String title);

  /// No description provided for @allStagesCompleted.
  ///
  /// In en, this message translates to:
  /// **'All 4 stages completed • Output ready'**
  String get allStagesCompleted;

  /// No description provided for @queuedToRetry.
  ///
  /// In en, this message translates to:
  /// **'Queued to retry from {stage}'**
  String queuedToRetry(String stage);

  /// No description provided for @stoppedAtStage.
  ///
  /// In en, this message translates to:
  /// **'Stopped at {stage} • {message}'**
  String stoppedAtStage(String stage, String message);

  /// No description provided for @selectVideoSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Video Source'**
  String get selectVideoSourceTitle;

  /// No description provided for @galleryOption.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get galleryOption;

  /// No description provided for @fileOption.
  ///
  /// In en, this message translates to:
  /// **'From File'**
  String get fileOption;

  /// No description provided for @couldNotReadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected video file.'**
  String get couldNotReadVideo;

  /// No description provided for @advancedAudioTuning.
  ///
  /// In en, this message translates to:
  /// **'Advanced Audio Tuning'**
  String get advancedAudioTuning;

  /// No description provided for @noVoiceSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noVoiceSelected;

  /// No description provided for @terminateProcessTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate Process?'**
  String get terminateProcessTitle;

  /// No description provided for @terminateProcessBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop the ongoing translation and TTS synthesis? This will abort the current video render.'**
  String get terminateProcessBody;

  /// No description provided for @processTerminated.
  ///
  /// In en, this message translates to:
  /// **'Dubbing process terminated.'**
  String get processTerminated;

  /// No description provided for @removeFromQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue?'**
  String get removeFromQueueTitle;

  /// No description provided for @removeFromQueueBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from the queue? This video has not started processing yet, so nothing will be rendered for it.'**
  String removeFromQueueBody(Object title);

  /// No description provided for @removedFromQueue.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from queue.'**
  String removedFromQueue(Object title);

  /// No description provided for @jobNoLongerInQueue.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer in the queue.'**
  String get jobNoLongerInQueue;

  /// No description provided for @processingActiveTask.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingActiveTask;

  /// No description provided for @completedRecentJobs.
  ///
  /// In en, this message translates to:
  /// **'Recently Completed'**
  String get completedRecentJobs;

  /// No description provided for @failedJobs.
  ///
  /// In en, this message translates to:
  /// **'Failed Jobs'**
  String get failedJobs;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @emptyStateEmptyQueue.
  ///
  /// In en, this message translates to:
  /// **'No dubbing jobs yet'**
  String get emptyStateEmptyQueue;

  /// No description provided for @emptyStateEmptyQueueBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a video and a voice on the Dub screen, then tap \"Start AI Khmer Dubbing\" to begin processing.'**
  String get emptyStateEmptyQueueBody;

  /// No description provided for @emptyStateEmptyPlayer.
  ///
  /// In en, this message translates to:
  /// **'No dubbed video yet'**
  String get emptyStateEmptyPlayer;

  /// No description provided for @emptyStateEmptyPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a job in the Queue, then tap \"Play\" on it to watch the rendered Khmer dub here.'**
  String get emptyStateEmptyPlayerBody;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingLabel;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved to Gallery'**
  String get savedLabel;

  /// No description provided for @retrySaveToGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry Save to Gallery'**
  String get retrySaveToGalleryLabel;

  /// No description provided for @loadErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening this video.'**
  String get loadErrorUnknown;

  /// No description provided for @copyFullReport.
  ///
  /// In en, this message translates to:
  /// **'Copy full report'**
  String get copyFullReport;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard'**
  String get reportCopied;

  /// No description provided for @pipelineError.
  ///
  /// In en, this message translates to:
  /// **'Pipeline error'**
  String get pipelineError;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @selectVoiceModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Voice Mode'**
  String get selectVoiceModeTitle;

  /// No description provided for @chunkEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No video selected'**
  String get chunkEmptyTitle;

  /// No description provided for @chunkEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a video file to split it into 7-minute chunks using AI silence detection.'**
  String get chunkEmptyBody;

  /// No description provided for @chunkSelectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get chunkSelectVideo;

  /// No description provided for @chunkStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start AI Chunking'**
  String get chunkStartButton;

  /// No description provided for @chunkProcessing.
  ///
  /// In en, this message translates to:
  /// **'AI is processing...'**
  String get chunkProcessing;

  /// No description provided for @chunkExtractingAudio.
  ///
  /// In en, this message translates to:
  /// **'Extracting audio...'**
  String get chunkExtractingAudio;

  /// No description provided for @chunkDetectingSilence.
  ///
  /// In en, this message translates to:
  /// **'Detecting silence gaps...'**
  String get chunkDetectingSilence;

  /// No description provided for @chunkFindingCutPoint.
  ///
  /// In en, this message translates to:
  /// **'Finding optimal cut point...'**
  String get chunkFindingCutPoint;

  /// No description provided for @chunkCuttingVideo.
  ///
  /// In en, this message translates to:
  /// **'Splitting video...'**
  String get chunkCuttingVideo;

  /// No description provided for @chunkComplete.
  ///
  /// In en, this message translates to:
  /// **'Chunking complete!'**
  String get chunkComplete;

  /// No description provided for @chunkChunksCreated.
  ///
  /// In en, this message translates to:
  /// **'{count} chunks created'**
  String chunkChunksCreated(Object count);

  /// No description provided for @chunkClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chunkClose;

  /// No description provided for @chunkError.
  ///
  /// In en, this message translates to:
  /// **'Chunking failed'**
  String get chunkError;

  /// No description provided for @chunkRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get chunkRestart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
