import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/islamic_calendar/models/important_event_timeline_item.dart';
import 'package:first_project/features/islamic_calendar/services/aladhan_api_service.dart';
import 'package:first_project/features/islamic_calendar/services/google_calendar_events_service.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/features/islamic_calendar/widgets/calendar_card.dart';
import 'package:first_project/features/islamic_calendar/widgets/calendar_header.dart';
import 'package:first_project/features/islamic_calendar/widgets/date_info_card.dart';
import 'package:first_project/features/islamic_calendar/widgets/event_chips.dart';
import 'package:first_project/features/islamic_calendar/widgets/important_events_card.dart';
import 'package:first_project/features/islamic_calendar/widgets/moon_card.dart';
import 'package:first_project/features/islamic_calendar/widgets/prayer_card.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final AladhanApiService _aladhanApi = AladhanApiService();
  final GoogleCalendarEventsService _googleCalendarEventsService = GoogleCalendarEventsService();
  Map<int, List<String>> _apiEventsByDay = const {}, _googleEventsByDay = const {};
  bool _eventsLoading = false;
  final ScrollController _importantEventsController = ScrollController();
  Timer? _importantEventsAutoScrollTimer;
  int _importantEventsScrollDirection = 1;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    _restartImportantEventsAutoScroll();
    unawaited(_loadMonthEvents());
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() => setState(() {});

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
      if (_selectedDate.year != _displayedMonth.year || _selectedDate.month != _displayedMonth.month) {
        _selectedDate = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
      }
    });
    _resetImportantEventsScroll();
    unawaited(_loadMonthEvents());
  }

  void _onSelectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  void _resetImportantEventsScroll() {
    if (_importantEventsController.hasClients) _importantEventsController.jumpTo(0);
    _importantEventsScrollDirection = 1;
  }

  void _restartImportantEventsAutoScroll() {
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _autoScrollImportantEvents());
  }

  void _autoScrollImportantEvents() {
    if (!mounted || !_importantEventsController.hasClients) return;
    final pos = _importantEventsController.position;
    if (pos.maxScrollExtent <= 0) return;
    var target = pos.pixels + (54.0 * _importantEventsScrollDirection);
    if (target >= pos.maxScrollExtent) { target = pos.maxScrollExtent; _importantEventsScrollDirection = -1; }
    else if (target <= 0) { target = 0; _importantEventsScrollDirection = 1; }
    _importantEventsController.animateTo(target, duration: const Duration(milliseconds: 420), curve: Curves.easeOut);
  }

  Future<void> _loadMonthEvents() async {
    setState(() => _eventsLoading = true);
    _apiEventsByDay = await _aladhanApi.fetchHolidays(year: _displayedMonth.year, month: _displayedMonth.month);
    try { _googleEventsByDay = await _googleCalendarEventsService.fetchMonthEvents(year: _displayedMonth.year, month: _displayedMonth.month); } catch (_) { _googleEventsByDay = {}; }
    if (mounted) setState(() => _eventsLoading = false);
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  String _eventSourceLabel() {
    if (_eventsLoading) return IslamicCalendarUtils.text('Syncing events...', 'ইভেন্ট সিঙ্ক হচ্ছে...');
    if (_googleEventsByDay.isNotEmpty && _apiEventsByDay.isNotEmpty) return IslamicCalendarUtils.text('Events from Google Calendar + API', 'Google Calendar + API ইভেন্ট');
    if (_googleEventsByDay.isNotEmpty) return IslamicCalendarUtils.text('Events from Google Calendar', 'Google Calendar থেকে ইভেন্ট');
    if (_apiEventsByDay.isNotEmpty) return IslamicCalendarUtils.text('Events from API', 'API থেকে ইভেন্ট');
    return IslamicCalendarUtils.text('Using offline mapped events', 'অফলাইন ম্যাপ করা ইভেন্ট');
  }

  PrayerTimes _prayerTimes(DateTime date) {
    final params = CalculationMethodParameters.karachi()..madhab = Madhab.hanafi;
    return PrayerTimes(date: DateTime(date.year, date.month, date.day), coordinates: Coordinates(IslamicCalendarUtils.dhakaLat, IslamicCalendarUtils.dhakaLng), calculationParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final selectedEvents = IslamicCalendarUtils.getEventsForDate(_selectedDate, _displayedMonth, _googleEventsByDay, _apiEventsByDay);
    final timelineItems = <ImportantEventTimelineItem>[];
    for (var i = -20; i <= 20; i++) {
      final date = _selectedDate.add(Duration(days: i));
      for (final event in IslamicCalendarUtils.getEventsForDate(date, _displayedMonth, _googleEventsByDay, _apiEventsByDay)) {
        timelineItems.add(ImportantEventTimelineItem(date: date, event: event, isSelectedDate: i == 0));
      }
    }

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
                  children: [
                    const CalendarHeader(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                      child: Text(
                        '${IslamicCalendarUtils.text('Today', 'আজ')}: ${IslamicCalendarUtils.formatGregorian(_selectedDate)} • ${IslamicCalendarUtils.formatHijri(_selectedDate)}',
                        style: TextStyle(color: glass.textPrimary, fontWeight: FontWeight.w700, fontSize: 18.sp),
                      ),
                    ),
                    MoonCard(selectedDate: _selectedDate),
                    SizedBox(height: 10.h),
                    CalendarCard(displayedMonth: _displayedMonth, selectedDate: _selectedDate, visibleDays: IslamicCalendarUtils.visibleDays(_displayedMonth), onMonthChange: _changeMonth, onSelectDate: _onSelectDate, eventsForDateProvider: (d) => IslamicCalendarUtils.getEventsForDate(d, _displayedMonth, _googleEventsByDay, _apiEventsByDay)),
                    EventChips(events: selectedEvents),
                    SizedBox(height: 12.h),
                    PrayerCard(prayers: _prayerTimes(_selectedDate), selectedDate: _selectedDate),
                    SizedBox(height: 10.h),
                    ImportantEventsCard(events: selectedEvents, timelineItems: timelineItems, eventSourceLabel: _eventSourceLabel(), timelineDateLabelProvider: (d) => '${IslamicCalendarUtils.digits(d.day.toString())} ${IslamicCalendarUtils.gregorianMonth(d.month)}', scrollController: _importantEventsController),
                    SizedBox(height: 10.h),
                    DateInfoCard(selectedDate: _selectedDate),
                  ],
                ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}
