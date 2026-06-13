part of '../screens/daily_activity_screen.dart';

mixin DailyControllerStateMixin on State<DailyActivityScreen> {
  // Instance-level (not static) so sibling controller mixins in the same
  // library can read them unqualified through the on-constraint chain.
  final double _kaabaLat = 21.422487;
  final double _kaabaLng = 39.826206;
  final double _baitulMukarramLat = 23.7286;
  final double _baitulMukarramLng = 90.4106;
  static const _baitulMukarramLabel = 'Baitul Mukarram, Dhaka';
  final int _apiMethod = 1; // University of Islamic Sciences, Karachi
  final int _apiSchool = 1; // Hanafi
  final int _prayerCarouselSeed = 1000;
  final int _prayerCarouselItemCount = 10000;

  late final Timer _clockTimer;
  DateTime _now = DateTime.now();
  // Incremented each time the home tab becomes visible again so the sun/moon
  // arc replays its sunrise/Maghrib → now sweep.
  int _arcReplayTick = 0;
  BottomNavProvider? _bottomNavProvider;
  double? _latitude;
  double? _longitude;
  bool _isFetchingPrayerSchedule = false;
  bool _ignoreNextLocationToggleChange = false;
  DailyPrayerSchedule? _todaySchedule;
  DailyPrayerSchedule? _tomorrowSchedule;
  DateTime? _lastPrayerCalcDate;
  DateTime? _nextSehriAt;
  DateTime? _nextIftarAt;
  bool _isRefreshingLocation = false;
  String _locationLabel = _baitulMukarramLabel;
  String _countdownLabel = 'Fajr in --:--:--';
  String _activePrayer = 'Zuhr';
  Duration _activeRemaining = Duration.zero;
  double _activeProgress = 0.0;
  Map<String, String> _prayerTimes = const {
    'Fajr': '--:--',
    'Zuhr': '--:--',
    'Asr': '--:--',
    'Maghrib': '--:--',
    'Isha': '--:--',
  };

  StreamSubscription<CompassEvent>? _homeCompassSub;
  double? _homeHeading;
  double? _homeQiblaBearing;
  final List<String> _prayerOrder = const [
    'Fajr',
    'Zuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];
  late final PageController _prayerPageController;
  String? _selectedPrayer;
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final QuranApiService _quranApiService = QuranApiService();
  final MosqueResultsCacheService _mosqueResultsCacheService =
      MosqueResultsCacheService();
  final Dio _prayerApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  int? _lastReadSurahNo;
  QuranChapter? _lastReadChapter;

  final List<ActivityItem> _activities = [
    ActivityItem(title: 'Alms', done: 4, total: 10),
    ActivityItem(title: 'Recite the Al Quran', done: 8, total: 10),
  ];
  final AmolTrackService _amolTrackService = AmolTrackService();
  int _amolScoreToday = 0;
  List<MosqueItem> _nearbyMosquePreview = const [];
  DateTime? _nearbyMosquePreviewUpdatedAt;
  bool _announcementModalChecked = false;
  bool _announcementModalFetchInProgress = false;
  static String? _lastShownAnnouncementId;

}
