import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String _location = '';
  String? _photoBase64;
  String? _photoUrl;

  String get name => _name;
  String get location => _location;
  String? get photoBase64 => _photoBase64;
  String? get photoUrl => _photoUrl;
  bool get hasProfile => _name.isNotEmpty;

  void setProfile({
    String? name,
    String? location,
    String? photoBase64,
    String? photoUrl,
  }) {
    var changed = false;
    if (name != null && name != _name) {
      _name = name;
      changed = true;
    }
    if (location != null && location != _location) {
      _location = location;
      changed = true;
    }
    if (photoBase64 != _photoBase64) {
      _photoBase64 = photoBase64;
      changed = true;
    }
    if (photoUrl != _photoUrl) {
      _photoUrl = photoUrl;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void clear() {
    _name = '';
    _location = '';
    _photoBase64 = null;
    _photoUrl = null;
    notifyListeners();
  }
}
