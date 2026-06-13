import 'package:flutter/foundation.dart';

/// Which calendar a date field is entered/displayed in.
enum CalendarType { gregorian, hijri, bengali }

/// Holds the present/birth dates and the calendar each is entered in for the
/// Boyos Zacai age calculator, driving the screen through Provider.
class BoyosZacaiProvider extends ChangeNotifier {
  DateTime _presentDate = DateTime.now();
  DateTime? _birthDate;
  CalendarType _presentCalendar = CalendarType.gregorian;
  CalendarType _birthCalendar = CalendarType.gregorian;

  DateTime get presentDate => _presentDate;
  DateTime? get birthDate => _birthDate;
  CalendarType get presentCalendar => _presentCalendar;
  CalendarType get birthCalendar => _birthCalendar;

  void setPresentDate(DateTime value) {
    _presentDate = value;
    notifyListeners();
  }

  void setBirthDate(DateTime value) {
    _birthDate = value;
    notifyListeners();
  }

  void setPresentCalendar(CalendarType value) {
    if (value == _presentCalendar) return;
    _presentCalendar = value;
    notifyListeners();
  }

  void setBirthCalendar(CalendarType value) {
    if (value == _birthCalendar) return;
    _birthCalendar = value;
    notifyListeners();
  }
}
