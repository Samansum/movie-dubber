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
  String get appTagline => 'កម្មវីធីកូនខ្មែរ';

  @override
  String get tabDub => 'បកប្រែរឿង';

  @override
  String get tabQueue => 'បញ្ជីការងា';

  @override
  String get tabPlayer => 'មើលវីដេអូ';

  @override
  String get tabSettings => 'ការកំណត់';

  @override
  String get tabChunking => 'បំបែករឿងភាគ';

  @override
  String get screenHomeTitle => 'CineDub AI';

  @override
  String get screenHomeSubtitle => 'កម្មវីធីកូនខ្មែរ';

  @override
  String get screenQueueTitle => 'បញ្ជីនៃការងាបកប្រែ';

  @override
  String get screenQueueSubtitle => 'ត្រួតពិនិត្យប្រព័ន្ធ';

  @override
  String get screenPlayerTitle => 'វីដេអូបកប្រែរួច';

  @override
  String get screenPlayerSubtitle => 'កន្លែកចាក់វីដេអូ';

  @override
  String get screenSettingsTitle => 'ការកំណត់';

  @override
  String get screenSettingsSubtitle => 'ការកំណត់ ភាសា Gemini និង TTS';

  @override
  String get screenChunkingTitle => 'ការបំបែកវីដេអូជារឿងភាគ';

  @override
  String get screenChunkingSubtitle => 'ប្រព័ន្ធបំបែកជោយប្រើ AI';

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
  String get keysPoolTitle => 'បន្ថែម Gemini API';

  @override
  String get keysPoolSubtitle =>
      'បន្ថែមពាក្រសំងាត់ API ច្រើនដើម្បីបកប្រែរឿងបានច្រើន។ ប្រព័ន្ធនិងផ្លាស់ប្តូរពាក្រសំងាត់ API ដោយស្វ័យប្រវត្តិពេលអស់លីមីត។';

  @override
  String get registeredKeys => 'ពាក្រសំងាត់ API ដែលបានរក្សាទុក';

  @override
  String configuredCount(int count) {
    return '$count ពាក្រសំងាត់';
  }

  @override
  String get addGeminiApiKey => 'បន្ថែមពាក្រសំងាត់ Gemini API';

  @override
  String get keyAliasLabel => 'ឈ្មោះសម្គាល់ / ការពិពណ៌នា';

  @override
  String get keyAliasHint => 'ឧ. Project Cinema Beta';

  @override
  String get geminiSecretTokenLabel => 'ថេកូនសម្ងាត់ Gemini API';

  @override
  String get tokenHint => 'AIzaSy...';

  @override
  String get addApiKeyButton => 'បន្ថែមពាក្រសំងាត់ API';

  @override
  String get invalidTokenMessage => 'សូមបញ្ចូលថេកូន Gemini ដែលត្រឹមត្រូវ។';

  @override
  String get apiKeySavedMessage => 'បានរក្សាទុកពាក្រសំងាត់ Gemini API!';

  @override
  String get copyMaskedTokenTooltip => 'ចម្លងពាក្រសំងាត់ដែលលាក់';

  @override
  String get deleteKeyTooltip => 'លុបពាក្រសំងាត់';

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
  String get khmerToneStyle => 'សំឡេង និងរចនាបថបែបខ្មែរ';

  @override
  String get keyRotationStrategy => 'យុទ្ធសាស្រ្តប្តូរពាក្រសំងាត់';

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
  String get resetDefaults => 'កំណត់លំនាំដើមឡើងវិញ';

  @override
  String get startDubbingButton => 'ចាប់ផ្តើមបកប្រែទៅភាសាខ្មែរដោយ AI';

  @override
  String get pipelineEstimate => '៤ ជំហាន • ពេលប៉ាន់ស្មាន: ~១នាទី ២០វិនាទី';

  @override
  String get clickToSelectSource => 'ចុចដើម្បីជ្រើសរើសវីដេអូដើមជាមុនសិន';

  @override
  String get preparingPreview => 'កំពុងរៀបចំវីដេអូមើលជាមុន…';

  @override
  String get clickToSelectVideo => 'ចុចដើម្បីជ្រើសរើសវីដេអូពីវិចិត្រសាល ឬឯកសារ';

  @override
  String get tapToPickVideo => 'ចុចដើម្បីជ្រើសរើសឯកសារវីដេអូពីឧបករណ៍របស់អ្នក';

  @override
  String get replaceButton => 'ប្តូរវីដេអូ';

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
    return 'កំហុសនៅក្នុងការផលិតវីដេអូ: $error';
  }

  @override
  String pipelineStartedFor(String video) {
    return 'បានចាប់ផ្តើមប្រព័ន្ធបកប្រែសម្រាប់ $video!';
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
  String get terminateFailedMessage => 'បានបញ្ឈប់ដំណើរការបកប្រែ។';

  @override
  String get removeDialogTitle => 'លុបចេញពីបញ្ជី?';

  @override
  String removeDialogBody(String title) {
    return 'លុប \"$title\" ចេញពីបញ្ចី? វីដេអូនេះមិនទាន់ចាប់ផ្តើមដំណើរការនៅឡើយ ដូច្នេះគ្មានអ្វីត្រូវរៀបចំសម្រាប់វាទេ។';
  }

  @override
  String get removeConfirm => 'លុប';

  @override
  String removedFromQueueMessage(String title) {
    return 'បានលុប \"$title\" ចេញពីបញ្ចី។ ការងារនេះមិននៅក្នុងបញ្ចីទៀតទេ។';
  }

  @override
  String removedListedMessage(String title) {
    return 'បានលុប \"$title\" ចេញពីបញ្ចី។ ការងារនេះមិនត្រូវបានរាយនៅឡើយទេ។';
  }

  @override
  String get cancelButton => 'បោះបង់';

  @override
  String get emptyQueueTitle => 'មិនមានការងារបកប្រែនៅឡើយទេ';

  @override
  String get emptyQueueBodyLead =>
      'ជ្រើសរើសវីដេអូ និងសំឡេងនៅក្នុងផ្ទាំងបកប្រែរឿង រួចចុច ';

  @override
  String get emptyQueueBodyTail =>
      '\"ចាប់ផ្តើមបកប្រែទៅភាសារខ្មែរដោយ AI\" ដើម្បីចាប់ផ្តើមដំណើរការ។';

  @override
  String get queueTitle => 'បញ្ធីការងាការបកប្រែវីដេអូ';

  @override
  String get queueSubtitle => 'ម៉ូនិទ័រប្រព័ន្ធវីដេអូខ្មែរស្វ័យប្រវត្តិ';

  @override
  String get syncLive => 'ឡាយផ្ទាល់';

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
  String get removeFromQueueTooltip => 'លុបចេញពីបញ្ចី';

  @override
  String get recentlyCompletedSection => 'បានបញ្ចប់ថ្មីៗ';

  @override
  String get playButton => 'លេង';

  @override
  String get emptyPlayerTitle => 'មិនទាន់មានវីដេអូបកប្រែទេ';

  @override
  String get emptyPlayerBodyLead =>
      'បញ្ចប់ការងារមួយនៅក្នុងបញ្ចី រួចចុច \"លេង\" លើវាដើម្បីមើល ';

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
    return 'វីដេអូដែលបានរៀបមិនមាននៅលើថាសទៀតទេ:\n$path';
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
  String get licensePrompt =>
      'សូមបញ្ចូលពាក្រសំងាត់អាជ្ញាបណ្ណរបស់អ្នកដើម្បីបន្ត។';

  @override
  String get activateTitle => 'សកម្មភាព CineDub AI';

  @override
  String get activateBody =>
      'សូមបញ្ចូលពាក្រសំងាត់អាជ្ញាបណ្ណដែលអ្នកបានទទួល ដើម្បីសកម្មភាពឧបករណ៍នេះ។';

  @override
  String get licenseKeyLabel => 'ពាក្រសំងាត់អាជ្ញាបណ្ណ';

  @override
  String get licenseKeyHint => 'KD-XXXX-XXXX-XXXX';

  @override
  String get activateButton => 'សកម្មភាព';

  @override
  String get stageTitle1 => '១. កាត់យកសំឡេង';

  @override
  String get stageTitle2 => '២. ស្តាប់ និងបកប្រែ';

  @override
  String get stageTitle3 => '៣. បង្កើតសំឡេងភាសាខ្មែរ';

  @override
  String get stageTitle4 => '៤. ផលិតវីដេអូភាសាខ្មែរ';

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
  String get failedDesc0 => 'ការកាត់យកសំឡេងបានបរាជ័យ';

  @override
  String get failedDesc1 => 'ការស្តាប់ / ការបកប្រែបានបរាជ័យ';

  @override
  String get failedDesc2 => 'ការបង្កើតសំឡេងភាសាខ្មែរបានបរាជ័យ';

  @override
  String get failedDesc3 => 'ការរៀបចំវីដេអូបានបរាជ័យ';

  @override
  String get stage0Done => 'បានកាត់យកបណ្តាញសំឡេង WAV 48kHz';

  @override
  String get stage0Running => 'កំពុងកាត់យកបណ្តាញសំឡេងទៅ WAV 48kHz';

  @override
  String get stage0Pending => 'កំពុងរង់ចាំការកាត់យកសំឡេង';

  @override
  String get stage1Done => 'បានបញ្ចប់ការបកប្រែភាសាខ្មែរ';

  @override
  String get stage1Running => 'កំពុងបកប្រែសម្លេងទៅភាសាខ្មែរ';

  @override
  String get stage1Pending => 'ការបកប្រែភាសាខ្មែរកំពុងរង់ចាំ';

  @override
  String get stage2Done => 'បានរៀបចំសំឡេងភាសាខ្មែរ Edge-TTS';

  @override
  String get stage2Running => 'កំពុងបង្កើតសំឡេងភាសារខ្មែរ...';

  @override
  String get stage2Pending => 'ការបង្កើតសំឡេងភាសាខ្មែរកំពុងរង់ចាំ';

  @override
  String get stage3Done => 'បានរៀបចំឯកសារ MP4 បកប្រែរួច';

  @override
  String get stage3Running => 'កំពុងបញ្ចូលវីដេអូ និងសំឡេងភាសាខ្មែរ';

  @override
  String get stage3Pending => 'ការបញ្ចូលវីដេអូ និងសមតុល្យបបូរមាត្រកំពុងរង់ចាំ';

  @override
  String preparingPipeline(String title) {
    return 'កំពុងរៀបចំប្រព័ន្ធសម្រាប់ $title';
  }

  @override
  String waitingInQueue(int position) {
    return 'កំពុងរង់ចាំនៅលំដាប់ទី $position ក្នុងបញ្ចី';
  }

  @override
  String startingPipeline(String title) {
    return 'កំពុងចាប់ផ្តើមប្រព័ន្ធសម្រាប់ $title';
  }

  @override
  String get allStagesCompleted => 'បានបញ្ចប់ជំហានទាំង ៤ • លទ្ធផលរួចរាល់';

  @override
  String queuedToRetry(String stage) {
    return 'បានដាក់ក្នុងបញ្ចីដើម្បីសាកល្បងឡើងវិញពី $stage';
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
  String get couldNotReadVideo =>
      'មិនអាចតំណើការឯកសារវីដេអូដែលបានជ្រើសរើសបានទេ។';

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
  String get processTerminated => 'ដំណើរការបកប្រែត្រូវបានបញ្ឈប់។';

  @override
  String get removeFromQueueTitle => 'លុបចេញពីបញ្ចី?';

  @override
  String removeFromQueueBody(Object title) {
    return 'លុប \"$title\" ចេញពីបញ្ចី? វីដេអូនេះមិនទាន់ចាប់ផ្តើមដំណើរការទេ ដូច្នេះមិនមានការរៀបចំអ្វីទេ។';
  }

  @override
  String removedFromQueue(Object title) {
    return '\"$title\" ត្រូវបានលុបចេញពីបញ្ចី។';
  }

  @override
  String get jobNoLongerInQueue => 'ការងារនេះមិននៅក្នុងបញ្ចីទៀតទេ។';

  @override
  String get processingActiveTask => 'កំពុងដំណើរការ';

  @override
  String get completedRecentJobs => 'បានបញ្ចប់ថ្មីៗ';

  @override
  String get failedJobs => 'ការងារបរាជ័យ';

  @override
  String get liveBadge => 'ឡាយផ្ទាល់';

  @override
  String get emptyStateEmptyQueue => 'មិនទាន់មានការងារបកប្រែទេ';

  @override
  String get emptyStateEmptyQueueBody =>
      'ជ្រើសរើសវីដេអូ និងសំឡេងនៅអេក្រង់ Dub រួចចុច \"ចាប់ផ្តើមបកប្រែទៅភាសារខ្មែរដោយ AI\" ដើម្បីចាប់ផ្តើម។';

  @override
  String get emptyStateEmptyPlayer => 'មិនទាន់មានវីដេអូបកប្រែទេ';

  @override
  String get emptyStateEmptyPlayerBody =>
      'បញ្ចប់ការងារមួយនៅក្នុងបញ្ចីការងា រួចចុច \"Play\" លើវាដើម្បីមើលវីដេអូបកប្រែរួចនៅទីនេះ។';

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
  String get selectVoiceModeTitle => 'ជ្រើសរើសប្រភេទសំឡេង';

  @override
  String get chunkEmptyTitle => 'មិនមានវីដេអូត្រូវបានជ្រើសរើសទេ';

  @override
  String get chunkEmptyBody =>
      'ជ្រើសរើសឯកសារវីដេអូដើម្បីបំបែកវាជាភាគ 7 នាទីដោយប្រើ AI កាត់ត្រងចំណុចស្ងាត់។';

  @override
  String get chunkSelectVideo => 'ជ្រើសរើសវីដេអូ';

  @override
  String get chunkStartButton => 'ចាប់ផ្តើមបំបែករឿងពេញជារឿងភាគដោយ AI';

  @override
  String get chunkProcessing => 'AI កំពុងដំណើរការ...';

  @override
  String get chunkExtractingAudio => 'កំពុងកាត់សំឡេង...';

  @override
  String get chunkDetectingSilence => 'កំពុងស្វែងរកចន្លោះស្ងាត់...';

  @override
  String get chunkFindingCutPoint => 'កំពុងស្វែងរកចំណុចដែលត្រូវកាត់...';

  @override
  String get chunkCuttingVideo => 'កំពុងកាត់បំបែកវីដេអូ...';

  @override
  String get chunkComplete => 'ការបំបែកវីដេអូ រួចរាល់!';

  @override
  String chunkChunksCreated(Object count) {
    return '$count ភាគ បានបង្កើត';
  }

  @override
  String get chunkClose => 'បិទ';

  @override
  String get chunkError => 'ការបំបែកវីដេអូ បរាជ័យ';

  @override
  String get chunkRestart => 'ចាប់ផ្តើមម្តងទៀត';

  @override
  String get chunkClearAll => 'សម្អាតទាំងអស់';

  @override
  String get chunkSaveToGallery => 'រក្សាទុកទៅវិចិត្រសាល';

  @override
  String get chunkLoadingVideo => 'កំពុងផ្ទុកវីដេអូ...';

  @override
  String get playVideo => 'ចាក់វិដេអូ';
}
