import 'package:flutter/foundation.dart';

import 'package:first_project/shared/services/app_globals.dart';

/// Holds the editable photo state and save-in-progress flag for the edit
/// profile screen, persisting through the shared app preferences.
class EditProfileProvider extends ChangeNotifier {
  EditProfileProvider() {
    _photoBase64 = profilePhotoBase64Notifier.value;
    final remoteUrl = (profilePhotoUrlNotifier.value ?? '').trim();
    _photoUrl = remoteUrl.isEmpty ? null : remoteUrl;
  }

  String? _photoBase64;
  String? _photoUrl;
  bool _isSaving = false;
  bool _disposed = false;

  String? get photoBase64 => _photoBase64;
  String? get photoUrl => _photoUrl;
  bool get isSaving => _isSaving;

  void setPhoto(String base64) {
    _photoBase64 = base64;
    _safeNotify();
  }

  void removePhoto() {
    _photoBase64 = null;
    _photoUrl = null;
    _safeNotify();
  }

  Future<void> save({required String name, required String location}) async {
    _isSaving = true;
    _safeNotify();
    profileNameNotifier.value = name;
    profileLocationNotifier.value = location;
    profilePhotoBase64Notifier.value = _photoBase64;
    profilePhotoUrlNotifier.value = _photoUrl;
    await saveAppPreferences();
    if (_disposed) return;
    _isSaving = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
