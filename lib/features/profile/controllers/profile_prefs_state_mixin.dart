part of '../screens/profile_preferences_screen.dart';

/// Shared fields, localization helpers, and value decoders for the
/// profile preferences screen.
mixin ProfilePrefsStateMixin on State<ProfilePreferencesScreen> {
  final Color _teal = const Color(0xFF14A3B8);

  late final Stream<bool> _adminStream =
      AdminRoleService.instance.watchCurrentUserAdmin().asBroadcastStream();

  bool get _isBangla =>
      context.read<LanguageProvider>().current == AppLanguage.bangla;

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 5; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_looksMojibake(repaired)) return english;
    return _containsBangla(repaired) ? repaired : english;
  }

  String _fontSizeLabel(AppFontSize size) {
    if (!_isBangla) return appFontSizeLabel(size);
    switch (size) {
      case AppFontSize.small:
        return '\u099b\u09cb\u099f';
      case AppFontSize.medium:
        return '\u09ae\u09be\u099d\u09be\u09b0\u09bf';
      case AppFontSize.large:
        return '\u09ac\u09dc';
    }
  }

  String _translationLanguageLabel(String value) {
    if (!_isBangla) return value;
    if (value == 'Bangla') return '\u09ac\u09be\u0982\u09b2\u09be';
    if (value == 'English') return '\u0987\u0982\u09b0\u09c7\u099c\u09bf';
    return value;
  }

  Uint8List? _decodeProfilePhoto(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }
}
