import 'package:flutter/foundation.dart';

/// Holds the selected month/year for the Calendar & Waqt screen so the
/// selection survives rebuilds and drives the list via Provider instead of
/// local setState.
class CalendarWaqtProvider extends ChangeNotifier {
  CalendarWaqtProvider() {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  late int _selectedMonth;
  late int _selectedYear;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void setMonth(int month) {
    if (month == _selectedMonth) return;
    _selectedMonth = month;
    notifyListeners();
  }

  void setYear(int year) {
    if (year == _selectedYear) return;
    _selectedYear = year;
    notifyListeners();
  }
}
