import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screns/schedule/models/schedule_role.dart';
import '../screns/schedule/repository/fixture_schedules_repository.dart';
import '../screns/schedule/view/schedule_section.dart';

/// Отдельная точка входа: раздел «Графики» на фикстуре, без сервера.
///
/// Нужна, пока внешний вид не утверждён: заказчик просил ряд крупнее и значок
/// дефектных актов у объекта, и смотреть это через вход и оболочку подрядчика
/// с живой базой — долго и не про вёрстку.
///
/// Запуск:
///
///     flutter run -t lib/dev/schedules_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const SchedulesPreviewApp());
}

class SchedulesPreviewApp extends StatelessWidget {
  const SchedulesPreviewApp({Key? key}) : super(key: key);

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
      // Без `opener`: клик в строку здесь никуда не ведёт — экран объекта
      // смотрится своей точкой `schedule_object_preview.dart`. Меню — пустое:
      // боковое меню подрядчика тянет за собой вход в систему.
      home: ScheduleSection(
        role: ScheduleRole.admin,
        repository: FixtureSchedulesRepository(),
        drawer: const Drawer(),
      ),
    );
  }
}
