import 'package:dio/dio.dart';

class AladhanApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.aladhan.com/v1',
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    sendTimeout: const Duration(seconds: 12),
  ));

  Future<Map<int, List<String>>> fetchHolidays({
    required int year,
    required int month,
    double latitude = 23.8103,
    double longitude = 90.4125,
  }) async {
    try {
      final response = await _dio.get(
        '/calendar/$year/$month',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': 1,
        },
      );
      final map = <int, List<String>>{};
      for (final item in response.data['data']) {
        final day = int.tryParse(item['date']['gregorian']['day'].toString());
        final holidays = (item['date']['hijri']['holidays'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (day != null && holidays.isNotEmpty) map[day] = holidays;
      }
      return map;
    } catch (_) {
      return {};
    }
  }
}
