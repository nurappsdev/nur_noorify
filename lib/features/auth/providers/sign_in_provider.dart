import 'package:flutter/foundation.dart';

/// Holds the sign-in form's transient UI state (password visibility and the
/// in-flight loading flag) so the screen consumes it through Provider.
class SignInProvider extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setLoading(bool value) {
    if (value == _isLoading) return;
    _isLoading = value;
    notifyListeners();
  }
}
