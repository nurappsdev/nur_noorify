import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:first_project/shared/providers/bottom_nav_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/providers/theme_provider.dart';
import 'package:first_project/shared/providers/user_provider.dart';

List<SingleChildWidget> buildAppProviders() => <SingleChildWidget>[
  ChangeNotifierProvider<BottomNavProvider>(create: (_) => BottomNavProvider()),
  ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
  ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
  ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
];
