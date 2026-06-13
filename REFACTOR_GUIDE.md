# Noorify Refactor Guide — "no file over 200 lines"

Goal: every screen / controller / widget / provider file ≤ 200 lines, with **identical
visual appearance and behavior**. We keep the existing `provider` + `part`/`mixin`
architecture, so public APIs and the widget tree never change — code is only
**relocated**, never rewritten.

Verification after every file:

```bash
flutter analyze lib/features/<feature>
```

Baseline (pre-existing, unrelated to this work): 7 warnings in `lib/`
(unused `_buildTopHeader`, `_buildMosquePreviewCard`, `_displayPrayerSummary`,
`_banglaWeekdayLabel`, `_banglaSeasonLabel`, and 2 unused imports). A file is "clean"
when it adds **no new** errors/warnings beyond these.

---

## Folder structure (per feature)

```
lib/features/<feature>/
  screens/        # the StatefulWidget + part directives + State `with` clause (thin)
  controllers/    # State-logic mixin chain (one concern per file, all `part of` the screen)
  widgets/        # standalone reusable widgets (own classes/files)
    sections/     # view-section mixins that build slices of the screen (part of the screen)
  providers/      # ChangeNotifier classes (split via composition — see below)
  services/       # IO / API / persistence
  models/         # plain data classes
```

This is already the project's layout; the refactor just adds more, smaller files
inside `controllers/`, `widgets/`, and `widgets/sections/`.

---

## Archetype A — `part`/`mixin` screens (controller + sections)

Used by the home screen. The screen file is the *library*; controller/section logic
lives in `mixin … on State<XScreen>` files marked `part of` the screen.

### How to split a large mixin into a chain

Because every section mixin uses **transitive `on`-constraints**
(`on State<XScreen>, XControllerMixin, XViewBaseMixin`), a big mixin can be cut into a
**linear chain** of smaller mixins where:

- the **first** link holds the instance fields: `mixin XStateMixin on State<XScreen>`;
- each subsequent link adds the previous one to its `on` clause
  (`mixin XUtilsMixin on State<XScreen>, XStateMixin`), so it can call everything
  defined earlier;
- the **last** link keeps the **original mixin name** (the *facade*), so the screen's
  `with` clause and every section/view `on XControllerMixin` keep working unchanged —
  they transitively see the whole chain.

Order the links **topologically**: a link may only call members declared in an
*earlier* link. Leaf helpers (formatters, math, constants) go first; orchestrators
(`initState`, listeners, refresh loops) go last in the facade. If two methods call
each other (a cycle), keep them in the **same** link.

`with` clause order = chain order, ending with the facade, then the view/section
mixins:

```dart
class _XScreenState extends State<XScreen>
    with
        XStateMixin, XUtilsMixin, /* …chain… */ XControllerMixin /*facade*/,
        XViewBaseMixin, /* …section mixins… */ XViewMixin {
```

### Gotcha: `static` members are NOT shared across mixins

Instance members flow through the `on` chain; **`static` members do not**.

- `static const` config scalars referenced from sibling mixins → convert to
  **instance `final`** fields (identical values, now visible through the chain).
- A `static const` used inside **another field's initializer** must stay `static const`
  (initializers need a compile-time constant); reference it from other mixins as
  `XStateMixin._theConst`.
- An intentionally `static` mutable field (e.g. cross-instance de-dupe) stays `static`;
  qualify its references as `XStateMixin._field`.

### Extract code byte-for-byte

To guarantee Bangla/Arabic `\u…` string literals are unchanged, **extract exact line
ranges** from a pristine copy instead of retyping:

```bash
cp screen_mixin.dart /tmp/orig.dart
# then assemble each part file from sed -n 'START,ENDp' /tmp/orig.dart ranges
```

### Worked example (DONE, verified clean)

`controllers/daily_activity_controller_mixin.dart` (1721 lines) → 13 files, max 183:

```
daily_activity_state_mixin.dart            DailyControllerStateMixin        (fields)
daily_controller_utils_mixin.dart          DailyControllerUtilsMixin        (math, digits, parse)
daily_controller_format_mixin.dart         DailyControllerFormatMixin       (date formatting)
daily_controller_labels_mixin.dart         DailyControllerLabelsMixin       (localized strings)
daily_controller_prayer_calc_mixin.dart    DailyControllerPrayerCalcMixin   (night/carousel calc)
daily_controller_schedule_data_mixin.dart  DailyControllerScheduleDataMixin (API + builders)
daily_controller_alerts_core_mixin.dart    DailyControllerAlertsCoreMixin   (notification core)
daily_controller_alerts_mixin.dart         DailyControllerAlertsMixin       (schedule/cancel)
daily_controller_prayer_data_mixin.dart    DailyControllerPrayerDataMixin   (refresh/recalc/countdown)
daily_controller_location_mixin.dart       DailyControllerLocationMixin     (geo + labels)
daily_controller_loaders_mixin.dart        DailyControllerLoadersMixin      (quran/mosque/amol)
daily_controller_announcements_mixin.dart  DailyControllerAnnouncementsMixin(modal)
daily_activity_controller_mixin.dart       DailyActivityControllerMixin     (FACADE: init/dispose/listeners)
```

---

## Archetype B — files with a single >200-line method

A mixin chain can't shrink a file below 200 if one *method* is bigger than 200. First
**decompose the method** into sub-widget builders, then chain as in Archetype A.

Rule: extract a contiguous widget subtree into a new `Widget _buildX()` only when **no
local variable** defined above the cut is used inside it (so the move is behavior-neutral).
Example seam found in `sky_section_mixin.dart`'s `_buildSunArcCard` (226 lines): the
profile `ValueListenableBuilder` block (lines 301–473) uses only `this`/`context`, so it
lifts cleanly into `_buildSunArcProfileBlock()`, dropping the parent to ~30 lines.

---

## Archetype C — `ChangeNotifier` providers

Split a fat provider by **composition**, not inheritance, to preserve its public API:
keep the public `ChangeNotifier` as a thin coordinator and move cohesive logic into
plain helper classes/mixins it delegates to. Where state is purely additive, a `part`
+ `mixin on ChangeNotifier` chain (same mechanics as Archetype A) also works.

---

## File inventory (46 files > 200 lines)

Status legend: ✅ done · ▢ pending

- ✅ home/controllers/daily_activity_controller_mixin.dart (1721 → 13 files)
- ▢ profile/screens/profile_preferences_screen.dart (1466)
- ▢ islamic_calendar/screens/islamic_calendar_screen.dart (1383)
- ▢ dua/screens/dua_screen.dart (1275)
- ▢ quran/screens/quran_screen.dart (1213)
- ▢ home/providers/daily_activity_provider.dart (1116)
- ▢ mosque/screens/find_mosque_screen.dart (978)
- ▢ home/widgets/sections/sky_section_mixin.dart (927)
- ▢ age_calculator/screens/boyos_zacai_screen.dart (922)
- ▢ calendar_waqt/screens/calendar_waqt_screen.dart (788)
- ▢ amol_track/screens/amol_track_screen.dart (729)
- ▢ dua_jikir/screens/dua_jikir_screen.dart (726)
- ▢ auth/screens/signup_screen.dart (713)
- ▢ prayer_time/screens/prayer_times_screen.dart (699)
- ▢ admin/screens/admin_panel_screen.dart (691)
- ▢ discover/screens/discover_screen.dart (681)
- ▢ auth/screens/signin_screen.dart (667)
- ▢ qibla/screens/qibla_compass_screen.dart (665)
- ▢ home/widgets/sections/quick_actions_section_mixin.dart (665)
- ▢ home/widgets/sections/prayer_section_mixin.dart (601)
- ▢ home/widgets/home_sun_arc.dart (569)
- ▢ mosque/screens/set_location_screen.dart (544)
- ▢ chat/screens/chat_conversation_screen.dart (535)
- ▢ shared/services/app_globals.dart (512)
- ▢ hadith/screens/hadith_screen.dart (489)
- ▢ home/widgets/home_moon_arc.dart (458)
- ▢ home/widgets/sections/header_section_mixin.dart (391)
- ▢ prayer_time/providers/prayer_times_provider.dart (363)
- ▢ home/widgets/sections/qibla_meal_section_mixin.dart (362)
- ▢ asmaul_husna/screens/asma_screen.dart (335)
- ▢ zakat/screens/zakat_calculator_screen.dart (315)
- ▢ home/widgets/sections/forbidden_times_section_mixin.dart (314)
- ▢ profile/screens/edit_profile_screen.dart (313)
- ▢ tasbih/providers/tasbih_provider.dart (311)
- ▢ qibla/providers/qibla_provider.dart (280)
- ▢ quran/providers/quran_screen_provider.dart (270)
- ▢ leaderboard/screens/leaderboard_screen.dart (263)
- ▢ home/widgets/sections/tahajjud_section_mixin.dart (257)
- ▢ islamic_calendar/services/google_calendar_events_service.dart (243)
- ▢ auth/services/auth_service.dart (226)
- ▢ shared/services/push_notification_service.dart (225)
- ▢ home/widgets/home_activity_widgets.dart (224)
- ▢ chat/screens/chat_users_screen.dart (214)
- ▢ quran/widgets/surah_view_scaffold_mixin.dart (202)
- ▢ quran/widgets/surah_ayah_parts_mixin.dart (202)
- ▢ quran/controllers/surah_detail_sheets_mixin.dart (201)
