import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/l10n/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  static const _supportedLanguages = {
    'en': 'English',
    'hi': 'हिन्दी',
    'mr': 'मराठी',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
    'gu': 'ગુજરાતી',
    'bn': 'বাংলা',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.language ?? 'Language'),
      ),
      body: ListView.builder(
        itemCount: _supportedLanguages.length,
        itemBuilder: (context, index) {
          final languageCode = _supportedLanguages.keys.elementAt(index);
          final languageName = _supportedLanguages.values.elementAt(index);

          return ListTile(
            title: Text(languageName),
            trailing: currentLocale.languageCode == languageCode
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(Locale(languageCode));
            },
          );
        },
      ),
    );
  }
}
