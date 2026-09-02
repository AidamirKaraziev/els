import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../screns/schedule/object/wizard/fixture_schedule_wizard_data.dart';
import '../screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import '../screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import '../screns/schedule/object/wizard/view/schedule_wizard_screen.dart';

/// Отдельная точка входа: показать мастер расстановки графика на фикстуре.
///
/// Через экран объекта видно только один расклад — чистый год. Здесь их все
/// три плюс переключатель прошлогоднего графика, иначе исход «нет шаблона»
/// или пропуск шага «Точка отсчёта» приходится проверять на живой базе.
///
/// Запуск:
///
///     flutter run -t lib/dev/schedule_wizard_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleWizardPreviewApp());
}

class ScheduleWizardPreviewApp extends StatelessWidget {
  const ScheduleWizardPreviewApp({Key? key}) : super(key: key);

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
      home: const _WizardPicker(),
    );
  }
}

/// Выбор расклада перед открытием мастера.
class _WizardPicker extends StatefulWidget {
  const _WizardPicker({Key? key}) : super(key: key);

  @override
  State<_WizardPicker> createState() => _WizardPickerState();
}

class _WizardPickerState extends State<_WizardPicker> {
  bool _withKnownAnchor = false;

  void _open(WizardFixture fixture) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ScheduleWizardScreen(
          repository: FixtureScheduleWizardRepository(
            fixture: fixture,
            withKnownAnchor: _withKnownAnchor,
          ),
          programRepository: FixtureMaintenanceProgramRepository(),
          objectId: 1,
          year: DateTime.now().year + 1,
          modelId: 1,
          modelName: 'LIFT A388509',
          objectName: 'г. Краснодар, ул. Северная, 356',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text('Мастер расстановки — расклады'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SwitchListTile(
                value: _withKnownAnchor,
                onChanged: (bool value) =>
                    setState(() => _withKnownAnchor = value),
                title: const Text('Есть график за прошлый год'),
                subtitle: const Text('Шаг «Точка отсчёта» пропускается'),
              ),
              const SizedBox(height: 8.0),
              for (final WizardFixture fixture in WizardFixture.values)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _open(fixture),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.myColorGreenAuth,
                      foregroundColor: ColorApp.myColorWhite,
                      elevation: 0.0,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(fixture.title),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
