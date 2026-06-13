import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/screens/quran_bookmarks_screen.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_ayah_audio_service.dart';
import 'package:first_project/features/quran/services/quran_offline_download_service.dart';
import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/features/quran/services/quran_tafsir_service.dart';
import 'package:first_project/features/quran/services/quran_timing_service.dart';

part '../controllers/surah_detail_state_mixin.dart';
part '../controllers/surah_detail_audio_mixin.dart';
part '../controllers/surah_detail_bookmark_mixin.dart';
part '../controllers/surah_detail_data_mixin.dart';
part '../controllers/surah_detail_sheets_mixin.dart';
part '../controllers/surah_detail_single_ayah_mixin.dart';
part '../widgets/surah_ayah_parts_mixin.dart';
part '../widgets/surah_ayah_card_mixin.dart';
part '../widgets/surah_view_cards_mixin.dart';
part '../widgets/surah_audio_controls_mixin.dart';
part '../widgets/surah_audio_card_mixin.dart';
part '../widgets/surah_view_appbar_mixin.dart';
part '../widgets/surah_view_scaffold_mixin.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({
    super.key,
    required this.chapter,
    this.autoStartAudio = false,
    this.initialAyahNo,
  });

  final QuranChapter chapter;
  final bool autoStartAudio;
  final int? initialAyahNo;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen>
    with
        SurahDetailStateMixin,
        SurahDetailAudioMixin,
        SurahDetailBookmarkMixin,
        SurahDetailDataMixin,
        SurahDetailSheetsMixin,
        SurahDetailSingleAyahMixin,
        SurahDetailAyahPartsMixin,
        SurahDetailAyahCardMixin,
        SurahDetailViewCardsMixin,
        SurahDetailAudioControlsMixin,
        SurahDetailAudioCardMixin,
        SurahDetailAppbarMixin,
        SurahDetailScaffoldMixin {}
