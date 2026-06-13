import 'package:flutter/foundation.dart';

import 'package:first_project/features/asmaul_husna/models/asma_name.dart';
import 'package:first_project/features/asmaul_husna/services/asma_service.dart';

/// Holds the Asma Ul Husna list, load/error state and the search query so the
/// screen consumes everything through Provider instead of local setState.
class AsmaProvider extends ChangeNotifier {
  AsmaProvider() {
    loadAsmaNames();
  }

  final AsmaService _asmaService = AsmaService();

  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  String _query = '';
  List<AsmaName> _names = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AsmaName> get names => _names;

  List<AsmaName> get filteredNames {
    if (_query.isEmpty) return _names;
    return _names
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.arabic.contains(_query) ||
              item.transliteration.toLowerCase().contains(_query) ||
              item.englishMeaning.toLowerCase().contains(_query) ||
              item.banglaName.toLowerCase().contains(_query) ||
              item.banglaMeaning.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  void setQuery(String value) {
    final next = value.trim().toLowerCase();
    if (next == _query) return;
    _query = next;
    _safeNotify();
  }

  Future<void> loadAsmaNames() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final names = await _asmaService.loadAsmaNames();
      if (_disposed) return;
      _names = names;
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
