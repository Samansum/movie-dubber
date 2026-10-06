import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'generated/app_localizations_km.dart';

export 'generated/app_localizations.dart';

/// Synchronous lookup of the generated localizations.
///
/// [AppLocalizations.of] needs a [BuildContext], but a lot of the text this
/// app shows is produced far away from the widget tree: pipeline stage
/// titles/descriptions and badge text are built inside `AppState`, and the
/// foreground-service notification is built inside `main.dart`. Those callers
/// only know the selected [Locale], so this helper builds the matching
/// generated instance directly instead of going through an inherited widget.
///
/// English is the fallback: it is the template ARB, so every key is guaranteed
/// to exist there.
AppLocalizations stringsFor(Locale locale) {
  switch (locale.languageCode) {
    case 'km':
      return AppLocalizationsKm();
    case 'en':
    default:
      return AppLocalizationsEn();
  }
}
