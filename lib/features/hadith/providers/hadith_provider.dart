import 'package:flutter/foundation.dart';

import 'package:first_project/features/hadith/models/hadith_item.dart';
import 'package:first_project/features/hadith/services/hadith_service.dart';

/// Holds the hadith list, load/error state and the search query so the screen
/// consumes everything through Provider instead of local setState.
class HadithProvider extends ChangeNotifier {
  HadithProvider() {
    loadHadiths();
  }

  final HadithService _hadithService = HadithService();

  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  String _query = '';
  List<HadithItem> _hadiths = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HadithItem> get hadiths => _hadiths;

  List<HadithItem> get filteredHadiths {
    if (_query.isEmpty) return _hadiths;
    return _hadiths
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.category.toLowerCase().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  void setQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    _safeNotify();
  }

  Future<void> loadHadiths() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final hadiths = await _hadithService.loadHadiths();
      if (_disposed) return;
      _hadiths = hadiths;
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
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
