import 'package:flutter/foundation.dart';

/// Holds the sign-up form's transient UI state (password/confirm visibility,
/// the "save info" toggle and the in-flight loading flag) so the screen
/// consumes it through Provider.
class SignUpProvider extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saveInfo = true;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirm => _obscureConfirm;
  bool get saveInfo => _saveInfo;
  bool get isLoading => _isLoading;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  void setSaveInfo(bool value) {
    if (value == _saveInfo) return;
    _saveInfo = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    if (value == _isLoading) return;
    _isLoading = value;
    notifyListeners();
  }
}
