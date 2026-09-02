import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screns/schedule/models/schedule_role.dart';
import '../screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import '../screns/schedule/object/view/schedule_object_screen.dart';
import '../screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import '../screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';

/// Отдельная точка входа: показать экран графика объекта на фикстуре.
///
/// Нужна, пока внешний вид не утверждён. Обычный `main.dart` открывает экран
/// входа и ведёт человека через оболочку подрядчика — до нового экрана оттуда
/// пока нет дороги, а поднимать ради картинки сервер и базу незачем.
///
/// Запуск:
///
///     flutter run -t lib/dev/schedule_object_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleObjectPreviewApp());
}

class ScheduleObjectPreviewApp extends StatelessWidget {
  const ScheduleObjectPreviewApp({Key? key}) : super(key: key);

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
      home: ScheduleObjectScreen(
        objectId: 1,
        repository: FixtureScheduleObjectRepository(),
        // Мастер расстановки — тоже на фикстуре: эта точка входа показывает
        // экран без сервера, и уходить из неё в сеть одной кнопкой нельзя.
        // Живой мастер смотрится отдельной точкой `schedule_wizard_live.dart`.
        wizardRepository: (String modelName) =>
            const FixtureScheduleWizardRepository(),
        programRepository: FixtureMaintenanceProgramRepository(),
        role: ScheduleRole.admin,
        objectName: 'График',
      ),
    );
  }
}
