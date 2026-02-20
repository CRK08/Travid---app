/// Voice information model
class VoiceInfo {
  final String name;
  final String locale;
  final int quality;
  final String displayName;
  final String? gender;
  final String? accent;

  VoiceInfo({
    required this.name,
    required this.locale,
    required this.quality,
    required this.displayName,
    this.gender,
    this.accent,
  });

  /// Create from FlutterTts voice map
  factory VoiceInfo.fromMap(Map<dynamic, dynamic> map) {
    final name = map['name']?.toString() ?? '';
    final locale = map['locale']?.toString() ?? '';
    final quality = map['quality'] as int? ?? 0;

    // Extract gender from name
    String? gender;
    final nameLower = name.toLowerCase();
    if (nameLower.contains('female') || _isFemaleVoice(nameLower)) {
      gender = 'female';
    } else if (nameLower.contains('male') || _isMaleVoice(nameLower)) {
      gender = 'male';
    }

    // Extract accent from locale
    String? accent;
    final localeLower = locale.toLowerCase();
    if (localeLower.contains('us')) {
      accent = 'us';
    } else if (localeLower.contains('gb') || localeLower.contains('uk')) {
      accent = 'uk';
    } else if (localeLower.contains('in')) {
      accent = 'in';
    } else if (localeLower.contains('au')) {
      accent = 'au';
    }

    // Create display name
    final displayName = _createDisplayName(name, locale, gender, accent);

    return VoiceInfo(
      name: name,
      locale: locale,
      quality: quality,
      displayName: displayName,
      gender: gender,
      accent: accent,
    );
  }

  /// Check if voice name suggests female voice
  static bool _isFemaleVoice(String name) {
    const femaleNames = [
      'samantha', 'karen', 'victoria', 'susan', 'allison',
      'kate', 'sara', 'tessa', 'moira', 'fiona', 'serena'
    ];
    return femaleNames.any((n) => name.contains(n));
  }

  /// Check if voice name suggests male voice
  static bool _isMaleVoice(String name) {
    const maleNames = [
      'alex', 'daniel', 'tom', 'fred', 'ralph',
      'oliver', 'thomas', 'jorge', 'aaron'
    ];
    return maleNames.any((n) => name.contains(n));
  }

  /// Create user-friendly display name
  static String _createDisplayName(
    String name,
    String locale,
    String? gender,
    String? accent,
  ) {
    // Extract simple name from full identifier
    String simpleName = name;
    if (name.contains('.')) {
      simpleName = name.split('.').last;
    }
    if (simpleName.contains('-')) {
      simpleName = simpleName.split('-').first;
    }

    // Capitalize
    simpleName = simpleName[0].toUpperCase() + simpleName.substring(1);

    // Add gender and accent info
    final parts = <String>[simpleName];
    if (accent != null) {
      parts.add(accent.toUpperCase());
    }
    if (gender != null) {
      parts.add(gender[0].toUpperCase() + gender.substring(1));
    }

    return parts.join(' - ');
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locale': locale,
      'quality': quality,
      'displayName': displayName,
      'gender': gender,
      'accent': accent,
    };
  }

  @override
  String toString() => displayName;
}
