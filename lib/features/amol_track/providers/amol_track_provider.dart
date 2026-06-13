import 'package:flutter/foundation.dart';

import 'package:first_project/features/amol_track/models/amol_track_models.dart';
import 'package:first_project/features/amol_track/services/amol_track_service.dart';

/// Holds the Amol Track state — the selected day, its completed deed ids, which
/// sections are expanded and the initial load flag — persisting via the service.
class AmolTrackProvider extends ChangeNotifier {
  AmolTrackProvider() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _service.revision.addListener(_onRemoteChanged);
    _init();
  }

  final AmolTrackService _service = AmolTrackService();

  late DateTime _selectedDate;
  Set<String> _completed = <String>{};
  final Set<String> _expanded = {'fardh'};
  bool _loading = true;
  bool _disposed = false;

  DateTime get selectedDate => _selectedDate;
  Set<String> get completed => _completed;
  Set<String> get expanded => _expanded;
  bool get loading => _loading;

  /// Completed deed count for any [day] in the visible week strip.
  int completedCountFor(DateTime day) => _service.completedCountFor(day);

  /// Weighted score (0..[kAmolMaxScore]) for any [day], used by the day ring
  /// and the week/month trend views.
  int scoreFor(DateTime day) => _service.scoreFor(day);

  /// Weighted score for the currently selected day, derived from [completed]
  /// so it updates instantly as deeds are toggled.
  int get selectedScore => amolScoreForIds(_completed);

  Future<void> _init() async {
    await _service.load();
    if (_disposed) return;
    _completed = _service.completedFor(_selectedDate);
    _loading = false;
    _safeNotify();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _completed = _service.completedFor(_selectedDate);
    _safeNotify();
  }

  Future<void> toggle(AmolItem item) async {
    final nowDone = await _service.toggle(_selectedDate, item.id);
    if (_disposed) return;
    if (nowDone) {
      _completed.add(item.id);
    } else {
      _completed.remove(item.id);
    }
    _safeNotify();
  }

  void toggleSection(String id) {
    if (!_expanded.remove(id)) _expanded.add(id);
    _safeNotify();
  }

  /// Pulls fresh data for the selected day whenever the shared store changes —
  /// e.g. a Firestore snapshot from another device, or the initial cloud load
  /// landing after this provider was created.
  void _onRemoteChanged() {
    if (_disposed) return;
    _completed = _service.completedFor(_selectedDate);
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _service.revision.removeListener(_onRemoteChanged);
    super.dispose();
  }
}
