import 'package:flutter/foundation.dart';

/// Holds the search bar visibility and query for a single dua category screen.
class DuaCategoryProvider extends ChangeNotifier {
  bool _showSearch = false;
  String _query = '';

  bool get showSearch => _showSearch;
  String get query => _query;

  void setQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  void toggleSearch() {
    _showSearch = !_showSearch;
    notifyListeners();
  }
}
