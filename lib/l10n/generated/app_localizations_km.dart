// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'CineDub AI';

  @override
  String get appTagline => 'ម៉ាស៊ីនខ្មែរ';

  @override
  String get tabDub => 'សម្រង់';

  @override
  String get tabQueue => 'ជួរ';

  @override
  String get tabPlayer => 'បង្ហាញ';

  @override
  String get tabSettings => 'ការកំណត់';

  @override
  String get tabChunking => 'ចែក';

  @override
  String get screenHomeTitle => 'CineDub AI';

  @override
  String get screenHomeSubtitle => 'ម៉ាស៊ីនខ្មែរ';

  @override
  String get screenQueueTitle => 'ជួរការសម្រង់';

  @override
  String get screenQueueSubtitle => 'ម៉ូនិទ័រប្រព័ន្ធ';

  @override
  String get screenPlayerTitle => 'វីដេអូសម្រង់រួច';

  @override
  String get screenPlayerSubtitle => 'ស្ដូឌីអ្នកលេង';

  @override
  String get screenSettingsTitle => 'ការកំណត់សម្រង់';

  @override
  String get screenSettingsSubtitle => 'ការកំណត់ Gemini និង TTS';

  @override
  String get screenChunkingTitle => 'ការបំបែកវីដេអូ';

  @override
  String get screenChunkingSubtitle => 'ប្រព័ន្ធជែកដោយ AI';

  @override
  String get back => 'ត្រឡប់ក្រោយ';

  @override
  String get languageSectionTitle => 'ភាសាកម្មវិធី / App Language';

  @override
  String get languageSectionSubtitle =>
      'ជ្រើសរើសភាសាដែលប្រើនៅក្នុងកម្មវិធីទាំងមូល។ ការផ្លាស់ប្តូរមានសុពលភាពភ្លាមៗ។';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get languageSwitchedToEnglish => 'បានកំណត់ភាសាកម្មវិធីជាភាសាអង់គ្លេស។';

  @override
  String get languageSwitchedToKhmer => 'បានកំណត់ភាសាកម្មវិធីជាភាសាខ្មែរ។';

  @override
  String get keysPoolTitle => 'បូកគន្លឹះ Gemini API';

  @override
  String get keysPoolSubtitle =>
      'បន្ថែមគន្លឹះជាច្រើនដើម្បីលើកលែងកំណត់ RPM/TPM។ CineDub AI ប្តូរថេកូនសកម្មដោយស្វ័យប្រវត្តិអំឡុងការសម្រង់ភាសាខ្មែរពេញរឿង។';

  @override
  String get registeredKeys => 'គន្លឹះដែលបានចុះឈ្មោះ';

  @override
  String configuredCount(int count) {
    return '$count គន្លឹះ';
  }

  @override
  String get addGeminiApiKey => 'បន្ថែមគន្លឹះ Gemini API';

  @override
  String get keyAliasLabel => 'ឈ្មោះសម្គាល់ / ការពិពណ៌នា';

  @override
  String get keyAliasHint => 'ឧ. Project Cinema Beta';

  @override
  String get geminiSecretTokenLabel => 'ថេកូនសម្ងាត់ Gemini API';

  @override
  String get tokenHint => 'AIzaSy...';

  @override
  String get addApiKeyButton => 'បន្ថែមគន្លឹះ API';

  @override
  String get invalidTokenMessage => 'សូមបញ្ចូលថេកូន Gemini ដែលត្រឹមត្រូវ។';

  @override
  String get apiKeySavedMessage => 'បានរក្សាទុកគន្លឹះ Gemini API!';

  @override
  String get copyMaskedTokenTooltip => 'ចម្លងថេកូនដែលលាក់';

  @override
  String get deleteKeyTooltip => 'លុបគន្លឹះ';

  @override
  String copiedTokenMessage(String token) {
    return 'បានចម្លង $token ទៅឯកសារយោង!';
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
  String get statusActive => 'សកម្ម';

  @override
  String get statusStandby => 'រង់ចាំ';

  @override
  String get statusCooldown => 'ត្រជាក់';

  @override
  String get translationSectionTitle => 'ម៉ាស៊ីនបកប្រែ និងម៉ូដែល';

  @override
  String get defaultGeminiModel => 'ម៉ូដែល Gemini លំនាំដើម';

  @override
  String get khmerToneStyle => 'សំឡេង និងរចនាបថសម្រង់ខ្មែរ';

  @override
  String get keyRotationStrategy => 'យុទ្ធសាស្រ្តប្តូរគន្លឹះ';

  @override
  String get selectSourceVideo => 'ជ្រើសរើសវីដេអូដើម';

  @override
  String get chooseFromGalleryOrFile => 'ជ្រើសរើសពីវិចិត្រសាល ឬឯកសារ';

  @override
  String get selectVideoHint =>
      'ជ្រើសរើសឯកសារវីដេអូ MP4, MOV ឬ MKV ពីឧបករណ៍របស់អ្នក';

  @override
  String get selectVoiceMode => 'ជ្រើសរើសរបៀបសំឡេង';

  @override
  String get voiceModeHint => 'ជម្រើសតែមួយ • ច្រើនអ្នកនិយាយ ឬសំឡេងតែមួយ';

  @override
  String get audioTuningSection => 'ការកំណត់សំឡេង និងការសមតុល្យបបូរមាត្រ';

  @override
  String get voicePitchOffset => 'កម្រិតប៉ិចសំឡេង';

  @override
  String get speechSpeed => 'ល្បឿន និងចង្វាក់និយាយ';

  @override
  String get backgroundDucking => 'ការបន្ថយសំឡេងផ្ទៃក្រោយ';

  @override
  String get resetDefaults => 'កំណត់ឡើងវិញ';

  @override
  String get startDubbingButton => 'ចាប់ផ្តើមសម្រង់ខ្មែរ AI';

  @override
  String get pipelineEstimate => '៤ ជំហាន • ពេលប៉ាន់ស្មាន: ~១នាទី ២០វិនាទី';

  @override
  String get clickToSelectSource => 'ចុចដើម្បីជ្រើសរើសវីដេអូដើមជាមុនសិន';

  @override
  String get preparingPreview => 'កំពុងរៀបចំមើលជាមុន…';

  @override
  String get clickToSelectVideo => 'ចុចដើម្បីជ្រើសរើសវីដេអូពីវិចិត្រសាល ឬឯកសារ';

  @override
  String get tapToPickVideo => 'ចុចដើម្បីជ្រើសរើសឯកសារវីដេអូពីឧបករណ៍របស់អ្នក';

  @override
  String get replaceButton => 'ជំនួស';

  @override
  String get unableToReadVideo => 'មិនអាចអានឯកសារវីដេអូដែលបានជ្រើសរើសបានទេ។';

  @override
  String errorPickingFile(String error) {
    return 'កំហុសនៅក្នុងការជ្រើសរើសឯកសារ: $error';
  }

  @override
  String get couldNotLoadVideo => 'មិនអាចផ្ទុកឯកសារវីដេអូដែលបានជ្រើសរើសបានទេ។';

  @override
  String errorLoadingVideo(String error) {
    return 'កំហុសនៅក្នុងការផ្ទុកវីដេអូ: $error';
  }

  @override
  String get videoPreviewFailed => 'មិនអាចផ្ទុកវីដេអូនេះសម្រាប់មើលជាមុនបានទេ។';

  @override
  String errorReleasingPreview(String error) {
    return 'កំហុសនៅក្នុងការបញ្ឈប់មើលជាមុន: $error';
  }

  @override
  String pipelineStartedFor(String video) {
    return 'បានចាប់ផ្តើមប្រព័ន្ធសម្រង់សម្រាប់ $video!';
  }

  @override
  String get terminateDialogTitle => 'បញ្ឈប់ដំណើរការ?';

  @override
  String get terminateDialogBody =>
      'តើអ្នកពិតជាចង់បញ្ឈប់ការបកប្រែ និងការបង្កើតសំឡេង TTS ដែលកំពុងដំណើរការឬទេ? ការនេះនឹងលុបចោលការរៀបចំវីដេអូបច្ចុប្បន្ន។';

  @override
  String get terminateConfirm => 'បញ្ឈប់';

  @override
  String get terminateTooltip => 'បញ្ឈប់ដំណើរការ';

  @override
  String get terminateFailedMessage => 'បានបញ្ឈប់ដំណើរការសម្រង់។';

  @override
  String get removeDialogTitle => 'លុបចេញពីជួរ?';

  @override
  String removeDialogBody(String title) {
    return 'លុប \"$title\" ចេញពីជួរ? វីដេអូនេះមិនទាន់ចាប់ផ្តើមដំណើរការនៅឡើយ ដូច្នេះគ្មានអ្វីត្រូវរៀបចំសម្រាប់វាទេ។';
  }

  @override
  String get removeConfirm => 'លុប';

  @override
  String removedFromQueueMessage(String title) {
    return 'បានលុប \"$title\" ចេញពីជួរ។ ការងារនេះមិននៅក្នុងជួរទៀតទេ។';
  }

  @override
  String removedListedMessage(String title) {
    return 'បានលុប \"$title\" ចេញពីជួរ។ ការងារនេះមិនត្រូវបានរាយនៅឡើយទេ។';
  }

  @override
  String get cancelButton => 'បោះបង់';

  @override
  String get emptyQueueTitle => 'មិនមានការងារសម្រង់នៅឡើយទេ';

  @override
  String get emptyQueueBodyLead =>
      'ជ្រើសរើសវីដេអូ និងសំឡេងនៅក្នុងផ្ទាំងសម្រង់ រួចចុច ';

  @override
  String get emptyQueueBodyTail =>
      '\"ចាប់ផ្តើមសម្រង់ខ្មែរ AI\" ដើម្បីចាប់ផ្តើមដំណើរការ។';

  @override
  String get queueTitle => 'ជួរការសម្រង់';

  @override
  String get queueSubtitle => 'ម៉ូនិទ័រប្រព័ន្ធវីដេអូខ្មែរស្វ័យប្រវត្តិ';

  @override
  String get syncLive => 'ផ្ទាល់ខ្លួន';

  @override
  String get stageProgression => 'ជំហានដំណើរការ';

  @override
  String get failedJobsSection => 'ការងារបរាជ័យ';

  @override
  String get failedJobsBodyLead =>
      'ការរៀបចំទាំងនេះបានឈប់ដោយសារកំហុស។ ជំហានមុនកំហុសត្រូវបានសមាគមថាបានបញ្ចប់ ';

  @override
  String get failedJobsBodyTail => '។ អ្វីៗបន្ទាប់ពីនោះមិនបានដំណើរការទេ។';

  @override
  String failedStageBadge(int stage) {
    return 'បរាជ័យ • ជំហាន $stage';
  }

  @override
  String get queuedVideosSection => 'វីដេអូកំពុងរង់ចាំ';

  @override
  String queuedBadge(int position) {
    return 'រង់ចាំ #$position';
  }

  @override
  String get awaitingSlot =>
      'កំពុងរង់ចាំកន្លែងធ្វើការ • នឹងដំណើរការបន្ទាប់ពីការរៀបចំបច្ចុប្បន្ន';

  @override
  String get removeFromQueueTooltip => 'លុបចេញពីជួរ';

  @override
  String get recentlyCompletedSection => 'បានបញ្ចប់ថ្មីៗ';

  @override
  String get playButton => 'លេង';

  @override
  String get emptyPlayerTitle => 'មិនទាន់មានវីដេអូសម្រង់ទេ';

  @override
  String get emptyPlayerBodyLead =>
      'បញ្ចប់ការងារមួយនៅក្នុងជួរ រួចចុច \"លេង\" លើវាដើម្បីមើល ';

  @override
  String get emptyPlayerBodyTail => 'វីដេអូខ្មែរដែលបានរៀបចំនៅទីនេះ។';

  @override
  String voiceLabel(String name) {
    return 'សំឡេង: $name';
  }

  @override
  String playbackLabel(String current, String total) {
    return 'ការលេង $current / $total';
  }

  @override
  String get saveToGalleryButton => 'រក្សាទុកទៅវិចិត្រសាល';

  @override
  String get savingToGallery => 'កំពុងរក្សាទុក…';

  @override
  String get savedToGallery => 'បានរក្សាទុកទៅវិចិត្រសាល';

  @override
  String get retrySaveToGallery => 'សាកល្បងរក្សាទុកម្តងទៀត';

  @override
  String get noRenderedVideoYet => 'ការងារនេះមិនទាន់មានឯកសារវីដេអូរៀបចំរួចទេ។';

  @override
  String renderedVideoMissing(String path) {
    return 'វីដេអូដែលបានរៀបចំលែងមាននៅលើថាសទៀតទេ:\n$path';
  }

  @override
  String couldNotOpenVideo(String error) {
    return 'មិនអាចបើកវីដេអូនេះបានទេ:\n$error';
  }

  @override
  String get retryThisStage => 'សាកល្បងជំហាននេះម្តងទៀត';

  @override
  String pipelineErrorIn(String stage) {
    return 'កំហុសប្រព័ន្ធនៅក្នុង $stage';
  }

  @override
  String get rawErrorMessage => 'សារកំហុសដើម';

  @override
  String get noDetailsCaptured => '(មិនបានថតព័ត៌មានលម្អិតទេ)';

  @override
  String get copyErrorReport => 'ចម្លងរបាយការណ៍កំហុស';

  @override
  String get errorReportCopied => 'បានចម្លងរបាយការណ៍កំហុសទៅឯកសារយោង';

  @override
  String couldNotCopyError(String error) {
    return 'មិនអាចចម្លងទៅឯកសារយោងបានទេ: $error';
  }

  @override
  String get licensePrompt => 'សូមបញ្ចូលគន្លឹះអាជ្ញាបណ្ណរបស់អ្នកដើម្បីបន្ត។';

  @override
  String get activateTitle => 'សកម្មភាព CineDub AI';

  @override
  String get activateBody =>
      'សូមបញ្ចូលគន្លឹះអាជ្ញាបណ្ណដែលអ្នកបានទទួល ដើម្បីសកម្មភាពឧបករណ៍នេះ។';

  @override
  String get licenseKeyLabel => 'គន្លឹះអាជ្ញាបណ្ណ';

  @override
  String get licenseKeyHint => 'KD-XXXX-XXXX-XXXX';

  @override
  String get activateButton => 'សកម្មភាព';

  @override
  String get stageTitle1 => '១. ចាន់យកសំឡេង';

  @override
  String get stageTitle2 => '២. អាន និងបកប្រែ';

  @override
  String get stageTitle3 => '៣. បង្កើតសំឡេង';

  @override
  String get stageTitle4 => '៤. សាងវីដេអូ';

  @override
  String stageFallback(int index) {
    return 'ជំហាន $index';
  }

  @override
  String get badgeFailed => 'បរាជ័យ';

  @override
  String get badgeCompleted => 'បានបញ្ចប់';

  @override
  String get badgeInProgress => 'កំពុងដំណើរការ';

  @override
  String get badgeNextUp => 'បន្ទាប់មក';

  @override
  String get badgePending => 'រង់ចាំ';

  @override
  String get failedDesc0 => 'ការចាន់យកសំឡេងបានបរាជ័យ';

  @override
  String get failedDesc1 => 'ការអាន / ការបកប្រែបានបរាជ័យ';

  @override
  String get failedDesc2 => 'ការបង្កើតសំឡេងបានបរាជ័យ';

  @override
  String get failedDesc3 => 'ការរៀបចំវីដេអូបានបរាជ័យ';

  @override
  String get stage0Done => 'បានចាន់យកបណ្តាញសំឡេង WAV 48kHz';

  @override
  String get stage0Running => 'កំពុងចាន់យកបណ្តាញសំឡេងទៅ WAV 48kHz';

  @override
  String get stage0Pending => 'កំពុងរង់ចាំការចាន់យកសំឡេង';

  @override
  String get stage1Done => 'បានបញ្ចប់ការបកប្រែខ្មែរ';

  @override
  String get stage1Running => 'កំពុងបកប្រែសន្ទុះទៅខ្មែរ';

  @override
  String get stage1Pending => 'ការបកប្រែខ្មែរកំពុងរង់ចាំ';

  @override
  String get stage2Done => 'បានរៀបចំសំឡេងខ្មែរ Edge-TTS';

  @override
  String get stage2Running => 'កំពុងបង្កើតសំឡេង...';

  @override
  String get stage2Pending => 'ការបង្កើតសំឡេងកំពុងរង់ចាំ';

  @override
  String get stage3Done => 'បានរៀបចំឯកសារ MP4 សម្រង់រួច';

  @override
  String get stage3Running => 'កំពុងបញ្ចូលវីដេអូ និងសំឡេងខ្មែរ';

  @override
  String get stage3Pending => 'ការបញ្ចូលវីដេអូ និងសមតុល្យបបូរមាត្រកំពុងរង់ចាំ';

  @override
  String preparingPipeline(String title) {
    return 'កំពុងរៀបចំប្រព័ន្ធសម្រាប់ $title';
  }

  @override
  String waitingInQueue(int position) {
    return 'កំពុងរង់ចាំនៅលំដាប់ទី $position ក្នុងជួរ';
  }

  @override
  String startingPipeline(String title) {
    return 'កំពុងចាប់ផ្តើមប្រព័ន្ធសម្រាប់ $title';
  }

  @override
  String get allStagesCompleted => 'បានបញ្ចប់ជំហានទាំង ៤ • លទ្ធផលរួចរាល់';

  @override
  String queuedToRetry(String stage) {
    return 'បានដាក់ក្នុងជួរដើម្បីសាកល្បងឡើងវិញពី $stage';
  }

  @override
  String stoppedAtStage(String stage, String message) {
    return 'បានឈប់នៅ $stage • $message';
  }

  @override
  String get selectVideoSourceTitle => 'ជ្រើសរើសវីដេអូ';

  @override
  String get galleryOption => 'ពីវិចិត្រសាល';

  @override
  String get fileOption => 'ពីឯកសារ';

  @override
  String get couldNotReadVideo => 'មិនអាចអានឯកសារវីដេអូដែលបានជ្រើសរើសបានទេ។';

  @override
  String get advancedAudioTuning => 'ការកំណត់សំឡេងលម្អិត';

  @override
  String get noVoiceSelected => 'គ្មានបានជ្រើសរើសទេ';

  @override
  String get terminateProcessTitle => 'បញ្ឈប់ដំណើរការ?';

  @override
  String get terminateProcessBody =>
      'តើអ្នកប្រាកដថាចង់បញ្ឈប់ការបកប្រែ និង TTS? នឹងបោះបង់ការរៀបចំវីដេអូបច្ចុប្បន្ន។';

  @override
  String get processTerminated => 'ដំណើរការសម្រង់ត្រូវបានបញ្ឈប់។';

  @override
  String get removeFromQueueTitle => 'លុបចេញពីជួរ?';

  @override
  String removeFromQueueBody(Object title) {
    return 'លុប \"$title\" ចេញពីជួរ? វីដេអូនេះមិនទាន់ចាប់ផ្តើមដំណើរការទេ ដូច្នេះមិនមានការរៀបចំអ្វីទេ។';
  }

  @override
  String removedFromQueue(Object title) {
    return '\"$title\" ត្រូវបានលុបចេញពីជួរ។';
  }

  @override
  String get jobNoLongerInQueue => 'ការងារនេះមិននៅក្នុងជួរទៀតទេ។';

  @override
  String get processingActiveTask => 'កំពុងដំណើរការ';

  @override
  String get completedRecentJobs => 'បានបញ្ចប់ថ្មីៗ';

  @override
  String get failedJobs => 'ការងារបរាជ័យ';

  @override
  String get liveBadge => 'ផ្ទាល់ខ្លួន';

  @override
  String get emptyStateEmptyQueue => 'មិនទាន់មានការងារសម្រង់ទេ';

  @override
  String get emptyStateEmptyQueueBody =>
      'ជ្រើសរើសវីដេអូ និងសំឡេងនៅអេក្រង់ Dub រួចចុច \"Start AI Khmer Dubbing\" ដើម្បីចាប់ផ្តើម។';

  @override
  String get emptyStateEmptyPlayer => 'មិនទាន់មានវីដេអូសម្រង់ទេ';

  @override
  String get emptyStateEmptyPlayerBody =>
      'បញ្ចប់ការងារមួយនៅក្នុង Queue រួចចុច \"Play\" លើវាដើម្បីមើលខ្មែរសម្រង់នៅទីនេះ។';

  @override
  String get saveToGallery => 'រក្សាទុកទៅវិចិត្រសាល';

  @override
  String get savingLabel => 'កំពុងរក្សាទុក…';

  @override
  String get savedLabel => 'បានរក្សាទុកទៅវិចិត្រសាល';

  @override
  String get retrySaveToGalleryLabel => 'សាកល្បងរក្សាទុកម្តងទៀត';

  @override
  String get loadErrorUnknown => 'មានអ្វីមួយខូចនៅពេលបើកវីដេអូនេះ។';

  @override
  String get copyFullReport => 'ចម្លងរបាយការណ៍ពេញលេញ';

  @override
  String get reportCopied => 'បានចម្លងរបាយការណ៍ទៅឯកសារយោង';

  @override
  String get pipelineError => 'កំហុសប្រព័ន្ធ';

  @override
  String get cancelAction => 'បោះបង់';

  @override
  String get selectVoiceModeTitle => 'ជ្រើសរើសរបៀបសំឡេង';

  @override
  String get chunkEmptyTitle => 'មិនមានវីដេអូវាបានជ្រើសរើសទេ';

  @override
  String get chunkEmptyBody =>
      'ជ្រើសរើសឯកសារវីដេអូដើម្បីបំបែកវាជាញឹកញាប់ 7 នាទីដោយប្រើ AI សម្គាល់ភាពស្ងប់ស្ងាត់។';

  @override
  String get chunkSelectVideo => 'ជ្រើសរើសវីដេអូ';

  @override
  String get chunkStartButton => 'ចាប់ផ្តើម AI Chunking';

  @override
  String get chunkProcessing => 'AI សកម្មកំពុងដំណើរការ...';

  @override
  String get chunkExtractingAudio => 'កំពុងແຫូរសំឡេង...';

  @override
  String get chunkDetectingSilence => 'កំពុងស្វែងរកចន្លោះស្ងប់...';

  @override
  String get chunkFindingCutPoint => 'កំពុងស្វែងរកចំណុចកាត់...';

  @override
  String get chunkCuttingVideo => 'កំពុងបំបែកវីដេអូ...';

  @override
  String get chunkComplete => 'Chunking រួចរល់!';

  @override
  String chunkChunksCreated(Object count) {
    return '$count chunks បានបង្កើត';
  }

  @override
  String get chunkClose => 'បិទ';

  @override
  String get chunkError => 'Chunking បរាជ័យ';

  @override
  String get chunkRestart => 'ចាប់ផ្តើមម្តងទៀត';
}
