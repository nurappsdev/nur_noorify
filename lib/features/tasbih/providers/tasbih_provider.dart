import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/features/tasbih/models/tasbih_models.dart';
import 'package:first_project/features/tasbih/services/tasbih_service.dart';

/// Arabic/transliteration/meaning copy for a tasbih preset.
class TasbihCopy {
  const TasbihCopy({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final String arabic;
  final String transliteration;
  final String meaning;
}

/// Owns all tasbih counter state, persistence, the per-second reminder ticker
/// and the target-reached effect timer so the screen is a pure consumer.
class TasbihProvider extends ChangeNotifier {
  TasbihProvider() {
    hapticFeedbackEnabledNotifier.addListener(_onGlobalHapticChanged);
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const List<TasbihPreset> presets = <TasbihPreset>[
    TasbihPreset(id: 'subhanallah', label: 'Subhanallah', target: 33),
    TasbihPreset(id: 'alhamdulillah', label: 'Alhamdulillah', target: 33),
    TasbihPreset(id: 'allahuakbar', label: 'Allahu Akbar', target: 34),
    TasbihPreset(id: 'lailahaillallah', label: 'La ilaha illallah', target: 100),
    TasbihPreset(id: 'astaghfirullah', label: 'Astaghfirullah', target: 100),
  ];

  static const Map<String, TasbihCopy> copyMap = <String, TasbihCopy>{
    'subhanallah': TasbihCopy(
      arabic: 'سبحان الله',
      transliteration: 'Subhanallah',
      meaning: 'Glory be to Allah',
    ),
    'alhamdulillah': TasbihCopy(
      arabic: 'الحمد لله',
      transliteration: 'Alhamdulillah',
      meaning: 'All praise is for Allah',
    ),
    'allahuakbar': TasbihCopy(
      arabic: 'الله أكبر',
      transliteration: 'Allahu Akbar',
      meaning: 'Allah is the Greatest',
    ),
    'lailahaillallah': TasbihCopy(
      arabic: 'لا إله إلا الله',
      transliteration: 'La ilaha illallah',
      meaning: 'There is no god except Allah',
    ),
    'astaghfirullah': TasbihCopy(
      arabic: 'أستغفر الله',
      transliteration: 'Astaghfirullah',
      meaning: 'I seek forgiveness from Allah',
    ),
  };

  final TasbihService _service = TasbihService();
  Timer? _ticker;
  Timer? _targetEffectTimer;
  bool _disposed = false;

  TasbihCounterState _state = TasbihCounterState.initial();
  List<TasbihHistoryEntry> _history = const <TasbihHistoryEntry>[];
  DateTime? _sessionStartedAt;
  int _reminderStep = 0;
  String? _uiAlert;
  bool _loading = true;
  bool _targetReachedEffect = false;

  TasbihCounterState get state => _state;
  List<TasbihHistoryEntry> get history => _history;
  String? get uiAlert => _uiAlert;
  bool get loading => _loading;
  bool get targetReachedEffect => _targetReachedEffect;

  TasbihPreset get selectedPreset => presets.firstWhere(
    (preset) => preset.id == _state.regularPresetId,
    orElse: () => presets.first,
  );

  TasbihCopy get selectedCopy =>
      copyMap[selectedPreset.id] ?? copyMap.values.first;

  int get count => _state.regularCount;

  int get target => _state.regularTarget;

  int get todayTotal {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return _history
        .where((entry) {
          final d = entry.finishedAt;
          return DateTime(d.year, d.month, d.day) == day;
        })
        .fold<int>(0, (sum, entry) => sum + entry.count);
  }

  void _onGlobalHapticChanged() {
    if (_loading) return;
    final enabled = hapticFeedbackEnabledNotifier.value;
    if (_state.hapticEnabled == enabled) return;

    final next = _state.copyWith(hapticEnabled: enabled);
    _state = next;
    _safeNotify();
    unawaited(_save(next));
  }

  Future<void> _load() async {
    var state = await _service.readState();
    final history = await _service.readHistory();

    if (state.mode != TasbihMode.regular) {
      state = state.copyWith(
        mode: TasbihMode.regular,
        regularCount: state.currentCount,
      );
      await _save(state);
    }

    if (!presets.any((preset) => preset.id == state.regularPresetId)) {
      state = state.copyWith(
        regularPresetId: presets.first.id,
        regularTarget: presets.first.target,
      );
      await _save(state);
    }

    if (state.hapticEnabled != hapticFeedbackEnabledNotifier.value) {
      state = state.copyWith(
        hapticEnabled: hapticFeedbackEnabledNotifier.value,
      );
      await _save(state);
    }

    if (_disposed) return;
    _state = state;
    _history = history;
    _loading = false;
    _safeNotify();
  }

  Future<void> _save([TasbihCounterState? next]) async {
    await _service.saveState(next ?? _state);
  }

  Future<void> setPreset(TasbihPreset preset) async {
    if (_state.regularPresetId == preset.id) return;

    await finish(addHistory: count > 0);

    final next = _state.copyWith(
      mode: TasbihMode.regular,
      regularPresetId: preset.id,
      regularTarget: preset.target,
      regularCount: 0,
    );

    _state = next;
    _targetReachedEffect = false;
    _safeNotify();
    await _save(next);
  }

  /// Increments the counter; returns whether this tap reached the target so the
  /// screen can show its target-reached snackbar.
  Future<bool> increment() async {
    if (_state.hapticEnabled) {
      await HapticFeedback.selectionClick();
    }

    _sessionStartedAt ??= DateTime.now();
    _uiAlert = null;

    final next = _state.copyWith(regularCount: _state.regularCount + 1);
    final reachedTarget = count < target && next.regularCount >= target;

    _state = next;
    _safeNotify();
    await _save(next);

    if (_disposed) return false;
    if (reachedTarget) {
      await _triggerTargetReachedFeedback();
    }
    return reachedTarget && !_disposed;
  }

  Future<void> _triggerTargetReachedFeedback() async {
    _targetEffectTimer?.cancel();
    _targetReachedEffect = true;
    _safeNotify();

    if (_state.hapticEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.vibrate();
    }

    _targetEffectTimer = Timer(const Duration(milliseconds: 1400), () {
      _targetReachedEffect = false;
      _safeNotify();
    });
  }

  Future<void> resetCount() async {
    await finish(addHistory: count > 0);
  }

  Future<void> finish({required bool addHistory}) async {
    final beforeCount = count;
    final beforeTarget = target;
    final startedAt = _sessionStartedAt;
    final endedAt = DateTime.now();
    final seconds = startedAt == null
        ? 0
        : endedAt.difference(startedAt).inSeconds;

    final next = _state.copyWith(mode: TasbihMode.regular, regularCount: 0);

    _state = next;
    _sessionStartedAt = null;
    _reminderStep = 0;
    _uiAlert = null;
    _targetReachedEffect = false;
    _safeNotify();
    await _save(next);

    if (!addHistory || beforeCount <= 0) return;

    await _service.appendHistory(
      TasbihHistoryEntry(
        finishedAtMillis: endedAt.millisecondsSinceEpoch,
        mode: TasbihMode.regular,
        label: selectedPreset.label,
        count: beforeCount,
        target: beforeTarget,
        durationSeconds: seconds,
      ),
    );

    final history = await _service.readHistory();
    if (_disposed) return;
    _history = history;
    _safeNotify();
  }

  void _tick() {
    if (_disposed || _sessionStartedAt == null) return;

    final reminder = _state.reminderMinutes;
    if (reminder <= 0) return;

    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final step = elapsed.inSeconds ~/ (reminder * 60);
    if (step <= 0 || step <= _reminderStep) return;

    _reminderStep = step;
    if (_state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    _uiAlert = 'Reminder: you are counting for ${elapsed.inMinutes} min';
    _safeNotify();
  }

  Future<void> updateSettings({
    required int goal,
    required int reminderMinutes,
    required bool hapticEnabled,
  }) async {
    final next = _state.copyWith(
      dailyGoal: goal.clamp(10, 10000),
      reminderMinutes: reminderMinutes,
      hapticEnabled: hapticEnabled,
      mode: TasbihMode.regular,
    );

    _state = next;
    _safeNotify();
    await _save(next);
    hapticFeedbackEnabledNotifier.value = hapticEnabled;
    await saveAppPreferences();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    hapticFeedbackEnabledNotifier.removeListener(_onGlobalHapticChanged);
    _ticker?.cancel();
    _targetEffectTimer?.cancel();
    super.dispose();
  }
}
