import 'package:flutter/foundation.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/services/dua_service.dart';

/// Holds the full dua list and its load/error state for the Dua hub screen.
class DuaProvider extends ChangeNotifier {
  DuaProvider() {
    loadDuas();
  }

  final DuaService _duaService = DuaService();

  bool _isLoading = true;
  bool _disposed = false;
  String? _error;
  List<DuaItem> _duas = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DuaItem> get duas => _duas;

  Future<void> loadDuas() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final duas = await _duaService.loadDuas();
      if (_disposed) return;
      _duas = duas;
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
