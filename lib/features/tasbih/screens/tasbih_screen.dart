import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/features/tasbih/models/tasbih_models.dart';
import 'package:first_project/features/tasbih/services/tasbih_service.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihCopy {
  const _TasbihCopy({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final String arabic;
  final String transliteration;
  final String meaning;
}

class _TasbihScreenState extends State<TasbihScreen> {
  static const List<TasbihPreset> _presets = <TasbihPreset>[
    TasbihPreset(id: 'subhanallah', label: 'Subhanallah', target: 33),
    TasbihPreset(id: 'alhamdulillah', label: 'Alhamdulillah', target: 33),
    TasbihPreset(id: 'allahuakbar', label: 'Allahu Akbar', target: 34),
    TasbihPreset(
      id: 'lailahaillallah',
      label: 'La ilaha illallah',
      target: 100,
    ),
    TasbihPreset(id: 'astaghfirullah', label: 'Astaghfirullah', target: 100),
  ];

  static const Map<String, _TasbihCopy> _copyMap = <String, _TasbihCopy>{
    'subhanallah': _TasbihCopy(
      arabic: '\u0633\u0628\u062d\u0627\u0646 \u0627\u0644\u0644\u0647',
      transliteration: 'Subhanallah',
      meaning: 'Glory be to Allah',
    ),
    'alhamdulillah': _TasbihCopy(
      arabic: '\u0627\u0644\u062d\u0645\u062f \u0644\u0644\u0647',
      transliteration: 'Alhamdulillah',
      meaning: 'All praise is for Allah',
    ),
    'allahuakbar': _TasbihCopy(
      arabic: '\u0627\u0644\u0644\u0647 \u0623\u0643\u0628\u0631',
      transliteration: 'Allahu Akbar',
      meaning: 'Allah is the Greatest',
    ),
    'lailahaillallah': _TasbihCopy(
      arabic:
          '\u0644\u0627 \u0625\u0644\u0647 \u0625\u0644\u0627 \u0627\u0644\u0644\u0647',
      transliteration: 'La ilaha illallah',
      meaning: 'There is no god except Allah',
    ),
    'astaghfirullah': _TasbihCopy(
      arabic: '\u0623\u0633\u062a\u063a\u0641\u0631 \u0627\u0644\u0644\u0647',
      transliteration: 'Astaghfirullah',
      meaning: 'I seek forgiveness from Allah',
    ),
  };

  final TasbihService _service = TasbihService();
  Timer? _ticker;
  Timer? _targetEffectTimer;

  TasbihCounterState _state = TasbihCounterState.initial();
  List<TasbihHistoryEntry> _history = const <TasbihHistoryEntry>[];
  DateTime? _sessionStartedAt;
  int _reminderStep = 0;
  String? _uiAlert;
  bool _loading = true;
  bool _targetReachedEffect = false;

  TasbihPreset get _selectedPreset => _presets.firstWhere(
    (preset) => preset.id == _state.regularPresetId,
    orElse: () => _presets.first,
  );

  _TasbihCopy get _selectedCopy =>
      _copyMap[_selectedPreset.id] ?? _copyMap.values.first;

  int get _count => _state.regularCount;

  int get _target => _state.regularTarget;

  int get _todayTotal {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return _history
        .where((entry) {
          final d = entry.finishedAt;
          return DateTime(d.year, d.month, d.day) == day;
        })
        .fold<int>(0, (sum, entry) => sum + entry.count);
  }

  @override
  void initState() {
    super.initState();
    hapticFeedbackEnabledNotifier.addListener(_onGlobalHapticChanged);
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    hapticFeedbackEnabledNotifier.removeListener(_onGlobalHapticChanged);
    _ticker?.cancel();
    _targetEffectTimer?.cancel();
    super.dispose();
  }

  void _onGlobalHapticChanged() {
    if (_loading) return;
    final enabled = hapticFeedbackEnabledNotifier.value;
    if (_state.hapticEnabled == enabled) return;

    final next = _state.copyWith(hapticEnabled: enabled);
    if (mounted) {
      setState(() => _state = next);
    }
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

    if (!_presets.any((preset) => preset.id == state.regularPresetId)) {
      state = state.copyWith(
        regularPresetId: _presets.first.id,
        regularTarget: _presets.first.target,
      );
      await _save(state);
    }

    if (state.hapticEnabled != hapticFeedbackEnabledNotifier.value) {
      state = state.copyWith(
        hapticEnabled: hapticFeedbackEnabledNotifier.value,
      );
      await _save(state);
    }

    if (!mounted) return;
    setState(() {
      _state = state;
      _history = history;
      _loading = false;
    });
  }

  Future<void> _save([TasbihCounterState? next]) async {
    await _service.saveState(next ?? _state);
  }

  Future<void> _setPreset(TasbihPreset preset) async {
    if (_state.regularPresetId == preset.id) return;

    await _finish(addHistory: _count > 0);

    final next = _state.copyWith(
      mode: TasbihMode.regular,
      regularPresetId: preset.id,
      regularTarget: preset.target,
      regularCount: 0,
    );

    setState(() {
      _state = next;
      _targetReachedEffect = false;
    });
    await _save(next);
  }

  Future<void> _increment() async {
    if (_state.hapticEnabled) {
      await HapticFeedback.selectionClick();
    }

    _sessionStartedAt ??= DateTime.now();
    _uiAlert = null;

    final next = _state.copyWith(regularCount: _state.regularCount + 1);
    final reachedTarget = _count < _target && next.regularCount >= _target;

    setState(() => _state = next);
    await _save(next);

    if (!mounted) return;
    if (reachedTarget) {
      await _triggerTargetReachedFeedback();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target reached: ${_selectedPreset.label}')),
      );
    }
  }

  Future<void> _triggerTargetReachedFeedback() async {
    _targetEffectTimer?.cancel();
    if (mounted) {
      setState(() => _targetReachedEffect = true);
    }

    if (_state.hapticEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.vibrate();
    }

    _targetEffectTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _targetReachedEffect = false);
    });
  }

  Future<void> _resetCount() async {
    await _finish(addHistory: _count > 0);
  }

  Future<void> _finish({required bool addHistory}) async {
    final beforeCount = _count;
    final beforeTarget = _target;
    final startedAt = _sessionStartedAt;
    final endedAt = DateTime.now();
    final seconds = startedAt == null
        ? 0
        : endedAt.difference(startedAt).inSeconds;

    final next = _state.copyWith(mode: TasbihMode.regular, regularCount: 0);

    setState(() {
      _state = next;
      _sessionStartedAt = null;
      _reminderStep = 0;
      _uiAlert = null;
      _targetReachedEffect = false;
    });
    await _save(next);

    if (!addHistory || beforeCount <= 0) return;

    await _service.appendHistory(
      TasbihHistoryEntry(
        finishedAtMillis: endedAt.millisecondsSinceEpoch,
        mode: TasbihMode.regular,
        label: _selectedPreset.label,
        count: beforeCount,
        target: beforeTarget,
        durationSeconds: seconds,
      ),
    );

    final history = await _service.readHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  void _tick() {
    if (!mounted || _sessionStartedAt == null) return;

    final reminder = _state.reminderMinutes;
    if (reminder <= 0) return;

    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final step = elapsed.inSeconds ~/ (reminder * 60);
    if (step <= 0 || step <= _reminderStep) return;

    _reminderStep = step;
    if (_state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _uiAlert = 'Reminder: you are counting for ${elapsed.inMinutes} min';
    });
  }

  Future<void> _openSettings() async {
    final goalController = TextEditingController(
      text: _state.dailyGoal.toString(),
    );
    var reminder = _state.reminderMinutes;
    var haptic = _state.hapticEnabled;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: goalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Daily Goal'),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<int>(
                    initialValue: reminder,
                    decoration: const InputDecoration(labelText: 'Reminder'),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(value: 5, child: Text('Every 5 min')),
                      DropdownMenuItem(value: 10, child: Text('Every 10 min')),
                      DropdownMenuItem(value: 15, child: Text('Every 15 min')),
                    ],
                    onChanged: (value) {
                      setSheetState(() => reminder = value ?? 0);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vibration'),
                    value: haptic,
                    onChanged: (value) {
                      setSheetState(() => haptic = value);
                    },
                  ),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          final goal =
                              int.tryParse(goalController.text.trim()) ??
                              _state.dailyGoal;

                          final next = _state.copyWith(
                            dailyGoal: goal.clamp(10, 10000),
                            reminderMinutes: reminder,
                            hapticEnabled: haptic,
                            mode: TasbihMode.regular,
                          );

                          setState(() => _state = next);
                          await _save(next);
                          hapticFeedbackEnabledNotifier.value = haptic;
                          await saveAppPreferences();
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _target <= 0 ? 0.0 : (_count / _target).clamp(0.0, 1.0);
    final overallGoalProgress = _state.dailyGoal <= 0
        ? 0.0
        : (_todayTotal / _state.dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF142C4C),
              Color(0xFF102541),
              Color(0xFF0C1C33),
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = (constraints.maxHeight / 860).clamp(
                      0.76,
                      1.0,
                    );
                    final compact = scale < 0.9;

                    final horizontalPadding = 16.0 * scale;
                    final topButtonSize = 44.0 * scale;
                    final titleSize = 34.0 * scale;
                    final chipFontSize = 12.0 * scale;
                    final arabicSize = 34.0 * scale;
                    final translitSize = 21.0 * scale;
                    final countSize = 78.0 * scale;
                    final percentSize = 74.0 * scale;
                    final tapSize = 168.0 * scale;
                    final successOn = _targetReachedEffect;
                    final successColor = BrandColors.primaryLight;

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8 * scale,
                            horizontalPadding,
                            10 * scale,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0x1FFFFFFF),
                                      borderRadius: BorderRadius.circular(
                                        12 * scale,
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: topButtonSize,
                                      height: topButtonSize,
                                      child: IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 22.sp * scale,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0x1FFFFFFF),
                                      borderRadius: BorderRadius.circular(
                                        12 * scale,
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: topButtonSize,
                                      height: topButtonSize,
                                      child: IconButton(
                                        onPressed: _openSettings,
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.settings_outlined,
                                          color: Colors.white,
                                          size: 21.sp * scale,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                'RAMADAN KAREEM',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: BrandColors.primaryLight,
                                  letterSpacing: 0.9,
                                  fontSize: 10.5.sp * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3 * scale),
                              Text(
                                'Digital Tasbih',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              if (!compact) ...<Widget>[
                                SizedBox(height: 2 * scale),
                                Text(
                                  'Tap the bead to count dhikr',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFB9CAE1),
                                    fontSize: 13.sp * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              SizedBox(height: 8 * scale),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6 * scale,
                                runSpacing: 6 * scale,
                                children: _presets
                                    .map(
                                      (preset) => ChoiceChip(
                                        showCheckmark: false,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w * scale,
                                          vertical: 7.h * scale,
                                        ),
                                        label: Text(
                                          preset.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        selected:
                                            _selectedPreset.id == preset.id,
                                        selectedColor: BrandColors.primary,
                                        backgroundColor: const Color(
                                          0xFF253B58,
                                        ),
                                        labelStyle: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: chipFontSize,
                                        ),
                                        side: BorderSide(
                                          color: _selectedPreset.id == preset.id
                                              ? BrandColors.primaryLight
                                              : const Color(0xFF3A5375),
                                        ),
                                        onSelected: (_) => _setPreset(preset),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              SizedBox(height: 8 * scale),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w * scale,
                                  vertical: 12.h * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3556),
                                  borderRadius: BorderRadius.circular(
                                    16 * scale,
                                  ),
                                  border: Border.all(
                                    color: successOn
                                        ? successColor
                                        : const Color(0xFF2B486F),
                                    width: successOn ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      _selectedCopy.arabic,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: arabicSize,
                                        fontWeight: FontWeight.w700,
                                        height: 1.18,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    Text(
                                      _selectedCopy.transliteration,
                                      style: TextStyle(
                                        color: BrandColors.primaryLight,
                                        fontSize: translitSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2 * scale),
                                    Text(
                                      _selectedCopy.meaning,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFFBDD0E8),
                                        fontSize: 14.sp * scale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: successOn ? 1 : 0,
                                child: IgnorePointer(
                                  ignoring: !successOn,
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 6.h * scale),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w * scale,
                                      vertical: 6.h * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1A7ED9EE),
                                      borderRadius: BorderRadius.circular(999.r),
                                      border: Border.all(
                                        color: const Color(0x667ED9EE),
                                      ),
                                    ),
                                    child: Text(
                                      'Alhamdulillah! Target Complete',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: BrandColors.primaryLight,
                                        fontSize: 12.sp * scale,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '$_count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: countSize,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                ),
                              ),
                              Text(
                                'of $_target',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFB6C9E2),
                                  fontSize: 18.sp * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              SizedBox(
                                width: percentSize,
                                height: percentSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 5 * scale,
                                      backgroundColor: const Color(0xFF284468),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        successOn
                                            ? successColor
                                            : BrandColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).round()}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp * scale,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10 * scale),
                              GestureDetector(
                                onTap: _increment,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  width: tapSize,
                                  height: tapSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: <Color>[
                                        successOn
                                            ? const Color(0xFF93F2FF)
                                            : const Color(0xFF55D1EA),
                                        successOn
                                            ? const Color(0xFF27B5D0)
                                            : const Color(0xFF188DA8),
                                      ],
                                      radius: 0.86.r,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: successOn
                                            ? const Color(0xAA61E4FF)
                                            : const Color(0x6637C1DE),
                                        blurRadius: successOn ? 34 : 26,
                                        spreadRadius: successOn ? 5 : 2,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: successOn
                                          ? const Color(0xFFC6F7FF)
                                          : const Color(0xFF8EE3F4),
                                      width: 1.0 * scale,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        successOn
                                            ? Icons.check_circle_rounded
                                            : Icons.touch_app_rounded,
                                        color: Colors.white,
                                        size: 35.sp * scale,
                                      ),
                                      SizedBox(height: 2 * scale),
                                      Text(
                                        successOn ? 'DONE' : 'TAP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 21.sp * scale,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 10 * scale),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: SizedBox(
                                      height: 40 * scale,
                                      child: FilledButton.icon(
                                        onPressed: _count > 0
                                            ? _resetCount
                                            : null,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2D486B,
                                          ),
                                          foregroundColor: Colors.white,
                                          textStyle: TextStyle(
                                            fontSize: 13.sp * scale,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        icon: Icon(
                                          Icons.restart_alt_rounded,
                                          size: 16.sp * scale,
                                        ),
                                        label: const Text('Reset'),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Expanded(
                                    child: Container(
                                      height: 40 * scale,
                                      decoration: BoxDecoration(
                                        color: const Color(0x1A1EA8B8),
                                        borderRadius: BorderRadius.circular(
                                          10 * scale,
                                        ),
                                        border: Border.all(
                                          color: const Color(0x553BC2D4),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Total: $_todayTotal',
                                          style: TextStyle(
                                            color: BrandColors.primaryLight,
                                            fontSize: 14.sp * scale,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8 * scale),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99.r),
                                child: SizedBox(
                                  height: 8 * scale,
                                  child: LinearProgressIndicator(
                                    value: overallGoalProgress,
                                    backgroundColor: const Color(0xFF233B5D),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          BrandColors.primary,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                'Daily goal: $_todayTotal / ${_state.dailyGoal}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFC2D3E8),
                                  fontSize: 12.5.sp * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_uiAlert != null) ...<Widget>[
                                SizedBox(height: 6 * scale),
                                Text(
                                  _uiAlert!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: BrandColors.primaryLight,
                                    fontSize: 12.sp * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              SizedBox(height: 6 * scale),
                              Text(
                                '\u0631\u0645\u0636\u0627\u0646 \u0645\u0628\u0627\u0631\u0643',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0x99D9E8FF),
                                  fontSize: 14.sp * scale,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
