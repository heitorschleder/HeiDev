import 'package:flutter/material.dart';

import '../app_context.dart';
import 'app_localizations/app_localizations.dart';

AppLocalizations? _l10n;

@visibleForTesting
void initL10nForTesting(AppLocalizations value) => _l10n = value;

AppLocalizations get l10n {
  _l10n ??= localize();
  return _l10n!;
}

AppLocalizations localize() {
  final localizationContext = AppContext.localizationKey.currentContext;
  if (localizationContext == null) {
    throw Exception('No localization context found');
  }
  final localizations = AppLocalizations.of(localizationContext);
  if (localizations == null) {
    throw Exception('No AppLocalizations found on context');
  }
  return localizations;
}

class LocalizationScope extends StatelessWidget {
  const LocalizationScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(key: AppContext.localizationKey, builder: (_, _) => child);
  }
}
