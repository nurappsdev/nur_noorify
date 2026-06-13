import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:first_project/shared/services/app_globals.dart';

class MosqueUtils {
  static bool get isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  static bool looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 || unit == 0x00C2 || unit == 0x00E0 ||
          unit == 0x00D8 || unit == 0x00D9 || unit == 0x00D0 || unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  static String repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 2; i++) {
      if (!looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  static bool containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  static String text(String en, String bn) {
    if (!isBangla) return en;
    final repaired = repairMojibake(bn);
    if (looksMojibake(repaired)) return en;
    return containsBangla(repaired) ? repaired : en;
  }

  static String distanceText(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km >= 10) return '${km.toStringAsFixed(0)} km';
    return '${km.toStringAsFixed(1)} km';
  }

  static String lastUpdatedLabel(DateTime value) {
    final time = TimeOfDay.fromDateTime(value);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    final date = '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return '$date $hour:$minute $suffix';
  }
}
