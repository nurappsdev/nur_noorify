import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:first_project/firebase_options.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/shared/providers/app_providers.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/services/push_notification_service.dart';
import 'package:first_project/core/constants/app_routes.dart';
import 'package:first_project/core/constants/route_names.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  await initializeNotifications();
  await loadAppPreferences();
  runApp(
    MultiProvider(
      providers: buildAppProviders(),
      child: const MyApp(),
    ),
  );
  unawaited(initializePushNotifications());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildMaterialApp(AppFontSize fontSize, bool darkThemeEnabled) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Noorify',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromRGBO(30, 168, 184, 1),
        scaffoldBackgroundColor: BrandColors.screenBackground,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: BrandColors.primary,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      themeMode: darkThemeEnabled ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final textScale = appFontScale(fontSize);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Adjust this to your design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder<AppFontSize>(
          valueListenable: appFontSizeNotifier,
          builder: (context, fontSize, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: darkThemeEnabledNotifier,
              builder: (context, isDark, child) {
                return _buildMaterialApp(fontSize, isDark);
              },
            );
          },
        );
      },
    );
  }
}
