---
name: setstate-to-provider-migration
description: Ongoing migration of all setState() usage to Provider across the Noorify app
metadata:
  type: project
---

User wants ALL `setState()` eliminated app-wide and replaced with Provider (chosen "all 19 screens, one big pass" + "everything to Provider", 2026-06-06). Started on branch `nur`.

Two conversion patterns:
- **Global-notifier reactions** (the majority): screens did `appLanguageNotifier.addListener(_onLanguageChanged) -> setState(() {})`. Replace with `context.watch<LanguageProvider>()` (rebuild) + `context.read<LanguageProvider>()` in tap handlers; delete the manual listener/initState/dispose. Theme is already reactive via `Theme.of(context)` (ThemeProvider drives MaterialApp).
- **Local screen state**: create a per-feature `ChangeNotifier` in `lib/features/<x>/providers/`, mirroring [[quran_screen_provider pattern]] — private fields + getters, mutation methods that early-return on no-change then notifyListeners(), `_safeNotify()`+`_disposed` guard for async. Register with a scoped `ChangeNotifierProvider` wrapping the screen.

Source of truth for settings stays in `lib/shared/services/app_globals.dart` ValueNotifiers; LanguageProvider/ThemeProvider wrap them. Global providers registered in `lib/shared/providers/app_providers.dart`.

19 files / 132 setState calls. Heaviest: quran/surah_detail_screen.dart (32), quran/quran_screen.dart (20), tasbih (10). Verify each batch with `flutter analyze`.

DONE + green (7 screens, build verified each batch):
- dua_jikir_screen.dart — language-listener only; `context.watch/read<LanguageProvider>()`.
- calendar_waqt_screen.dart — `CalendarWaqtProvider` (month/year); public `CalendarWaqtScreen` is a wrapper supplying ChangeNotifierProvider over private `_CalendarWaqtView` (2 home-section call sites rely on its constructor — DO NOT change signature).
- qibla_compass_screen.dart — `QiblaProvider` owns compass stream/geolocation/API; sensor error as `QiblaSensorError` enum, widget localizes. `QiblaSource` enum in provider.
- asmaul_husna/asma_screen.dart — `AsmaProvider` (list/loading/error/query); TextEditingController stays in view, listener calls provider.setQuery.
- profile/edit_profile_screen.dart — `EditProfileProvider` (photo/url/isSaving + save); controllers + ImagePicker stay in view.
- hadith/hadith_screen.dart — `HadithProvider` (list/loading/error/query); mojibake `_text` + LanguageProvider in view.
- age_calculator/boyos_zacai_screen.dart — `BoyosZacaiProvider` (dates + calendars); `_CalendarType` enum moved to provider as public `CalendarType`.

ESTABLISHED PATTERN for "wrapper" screens: public `XScreen` becomes StatelessWidget returning `ChangeNotifierProvider(create: ..., child: const _XView())`; `_XView` is StatefulWidget keeping controllers/lifecycle (no setState); state getters delegate `context.read<XProvider>()`, build does `context.watch`.

DONE batch 4 (green): auth/signin (SignInProvider: obscure/isLoading), auth/signup (SignUpProvider: obscure/confirm/saveInfo/isLoading) — both keep app_globals import for the guest-setup language flow; amol_track (AmolTrackProvider: date/completed/expanded/loading; build uses Consumer2<LanguageProvider,AmolTrackProvider>; provider exposes completedCountFor(day)).

DONE batch 5 (green): dua/dua_screen.dart — TWO providers: DuaProvider (list/loading/error) for hub; DuaCategoryProvider (showSearch/query) for the pushed `_DuaCategoryScreen` (now wrapper→`_DuaCategoryView`). 3 ValueListenableBuilder<AppLanguage> swapped for Consumer/Consumer2 with LanguageProvider. `_MainCategoryScreen` is a pushed Stateless route → only LanguageProvider (global) is reachable in pushed routes, NOT the scoped DuaProvider — that's fine, it gets data via constructor.

NOTE: ValueListenableBuilder<AppLanguage> on appLanguageNotifier → replace with Consumer<LanguageProvider> (builder (context, lang, _) { final isBangla = lang.isBangla; }). For screens needing the scoped provider too, Consumer2.

DONE batch 6 (green): tasbih/tasbih_screen.dart — TasbihProvider owns state/history/timers(ticker+targetEffect)/haptic listener/service + counting logic; presets+copyMap+TasbihCopy moved into provider (TasbihProvider.presets, .copyMap public). increment() returns bool reachedTarget so view shows the snackbar; updateSettings() for the settings sheet. View getters delegate; build does context.watch<TasbihProvider>().

12/19 DONE. REMAINING 7: home/daily_activity_controller_mixin (2), home/prayer_section_mixin (4) [MIXINS on home_shell — trickiest, do LAST], islamic_calendar (5), mosque/set_location (7), mosque/find_mosque (7), quran/quran_screen (20), quran/surah_detail (32). quran already has QuranScreenProvider to extend/reuse.

Pre-existing analyzer warnings (NOT mine, ignore): unused _buildTopHeader, _buildMosquePreviewCard, _displayPrayerSummary, _banglaWeekdayLabel, _banglaSeasonLabel, unused imports in prayer_times_screen.dart & quran_screen.dart.

**Why:** big multi-file refactor; must stay compiling between batches.
**How to apply:** continue feature-by-feature, run flutter analyze after each batch, keep StatefulWidget where controller/stream lifecycle is needed (just remove setState).
