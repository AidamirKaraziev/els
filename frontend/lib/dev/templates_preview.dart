import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screns/schedule/templates/repository/fixture_templates_repository.dart';
import '../screns/schedule/templates/view/templates_screen.dart';

/// Отдельная точка входа: экран «Шаблоны ТО» и редактор на фикстуре.
///
/// Нужна, пока внешний вид не утверждён: кадра в Figma нет, и смотреть
/// экран через вход подрядчика с живой базой — долго и не про вёрстку.
///
/// Запуск:
///
///     flutter run -t lib/dev/templates_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const TemplatesPreviewApp());
}

class TemplatesPreviewApp extends StatelessWidget {
  const TemplatesPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('ru', '')],
      theme: ThemeData(textTheme: GoogleFonts.ubuntuTextTheme()),
      home: TemplatesScreen(repository: FixtureTemplatesRepository()),
    );
  }
}
