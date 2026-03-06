import 'package:flutter/material.dart';

const Locale kFallbackLocale = Locale('en');
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('es'),
  Locale('ko'),
];

String localeLabelKey(Locale locale) {
  switch (locale.languageCode) {
    case 'es':
      return 'settings.language.spanish';
    case 'ko':
      return 'settings.language.korean';
    case 'en':
    default:
      return 'settings.language.english';
  }
}
