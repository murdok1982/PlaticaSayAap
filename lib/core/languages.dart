class Language {
  final String code;
  final String nativeName;
  final String englishName;
  final String flagEmoji;
  final String whisperCode;
  final String ttsLocale;
  final int packSizeMb;

  const Language({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flagEmoji,
    required this.whisperCode,
    required this.ttsLocale,
    this.packSizeMb = 38,
  });

  bool get isBaseLanguage => code == 'es' || code == 'en';
}

class Languages {
  static const spanish = Language(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    flagEmoji: '🇪🇸',
    whisperCode: 'es',
    ttsLocale: 'es-ES',
    packSizeMb: 0, // Incluido de serie en el motor base
  );

  static const english = Language(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    flagEmoji: '🇺🇸',
    whisperCode: 'en',
    ttsLocale: 'en-US',
    packSizeMb: 0, // Incluido de serie en el motor base
  );

  static const chinese = Language(
    code: 'zh',
    nativeName: '中文 (Mandarín)',
    englishName: 'Chinese',
    flagEmoji: '🇨🇳',
    whisperCode: 'zh',
    ttsLocale: 'zh-CN',
    packSizeMb: 35,
  );

  static const arabic = Language(
    code: 'ar',
    nativeName: 'العربية',
    englishName: 'Arabic',
    flagEmoji: '🇸🇦',
    whisperCode: 'ar',
    ttsLocale: 'ar-SA',
    packSizeMb: 35,
  );

  static const portuguese = Language(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    flagEmoji: '🇧🇷',
    whisperCode: 'pt',
    ttsLocale: 'pt-BR',
    packSizeMb: 35,
  );

  static const french = Language(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    flagEmoji: '🇫🇷',
    whisperCode: 'fr',
    ttsLocale: 'fr-FR',
    packSizeMb: 35,
  );

  static const german = Language(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    flagEmoji: '🇩🇪',
    whisperCode: 'de',
    ttsLocale: 'de-DE',
    packSizeMb: 35,
  );

  static const russian = Language(
    code: 'ru',
    nativeName: 'Русский',
    englishName: 'Russian',
    flagEmoji: '🇷🇺',
    whisperCode: 'ru',
    ttsLocale: 'ru-RU',
    packSizeMb: 35,
  );

  static const hindi = Language(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    flagEmoji: '🇮🇳',
    whisperCode: 'hi',
    ttsLocale: 'hi-IN',
    packSizeMb: 35,
  );

  static const japanese = Language(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    flagEmoji: '🇯🇵',
    whisperCode: 'ja',
    ttsLocale: 'ja-JP',
    packSizeMb: 38,
  );

  static const italian = Language(
    code: 'it',
    nativeName: 'Italiano',
    englishName: 'Italian',
    flagEmoji: '🇮🇹',
    whisperCode: 'it',
    ttsLocale: 'it-IT',
    packSizeMb: 32,
  );

  static const korean = Language(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    flagEmoji: '🇰🇷',
    whisperCode: 'ko',
    ttsLocale: 'ko-KR',
    packSizeMb: 36,
  );

  static const turkish = Language(
    code: 'tr',
    nativeName: 'Türkçe',
    englishName: 'Turkish',
    flagEmoji: '🇹🇷',
    whisperCode: 'tr',
    ttsLocale: 'tr-TR',
    packSizeMb: 32,
  );

  static const vietnamese = Language(
    code: 'vi',
    nativeName: 'Tiếng Việt',
    englishName: 'Vietnamese',
    flagEmoji: '🇻🇳',
    whisperCode: 'vi',
    ttsLocale: 'vi-VN',
    packSizeMb: 34,
  );

  static const indonesian = Language(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    englishName: 'Indonesian',
    flagEmoji: '🇮🇩',
    whisperCode: 'id',
    ttsLocale: 'id-ID',
    packSizeMb: 30,
  );

  static const all = <Language>[
    spanish,
    english,
    chinese,
    arabic,
    portuguese,
    french,
    german,
    russian,
    hindi,
    japanese,
    italian,
    korean,
    turkish,
    vietnamese,
    indonesian,
  ];

  static Language? byCode(String code) {
    for (final lang in all) {
      if (lang.code.toLowerCase() == code.toLowerCase()) return lang;
    }
    return null;
  }
}
