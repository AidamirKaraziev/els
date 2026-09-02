import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import 'draft/draft_preview_page.dart';
import 'draft/draft_program_data.dart';

/// Отдельная точка входа: набросок нового «Предпросмотра» и окна
/// «Программа модели» на фикстуре.
///
/// Боевой мастер эта точка не открывает и ничего в нём не меняет: набросок
/// сначала утверждается глазами, и только потом переезжает в бой.
///
/// Запуск:
///
///     flutter run -t lib/dev/schedule_program_draft.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleProgramDraftApp());
}

class ScheduleProgramDraftApp extends StatelessWidget {
  const ScheduleProgramDraftApp({Key? key}) : super(key: key);

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
      home: const _DraftPicker(),
    );
  }
}

/// Выбор расклада перед открытием страницы: три состояния программы, из-за
/// которых страница выглядит по-разному.
class _DraftPicker extends StatelessWidget {
  const _DraftPicker({Key? key}) : super(key: key);

  void _open(BuildContext context, DraftFixture fixture) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DraftPreviewPage(fixture: fixture),
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
        title: const Text(
          'Набросок: программа модели',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: ColorApp.myColorBlack,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520.0),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(ColorApp.kPadding),
            children: <Widget>[
              const Text(
                'Объект 25, график на 2028, цикл с марта. Логики нет: '
                'программа и перенос ТО живут в памяти страницы, в базу '
                'ничего не уходит.',
                style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
              ),
              const SizedBox(height: 20.0),
              for (final DraftFixture fixture in DraftFixture.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () => _open(context, fixture),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.myColorWhite,
                      foregroundColor: ColorApp.myColorBlack,
                      elevation: 0.0,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 18.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(
                          color: ColorApp.myColorGrayBorder,
                        ),
                      ),
                    ),
                    child: Text(
                      fixture.title,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
