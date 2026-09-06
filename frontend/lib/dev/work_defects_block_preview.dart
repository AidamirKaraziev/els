/// Набросок блока «Дефекты» в карточке работы по ТО — вид без сервера и входа.
///
/// Кадра в макете нет. Блок показан на месте, где ему стоять: между
/// чек-листом и временами карточки работы
/// (`screns/schedule/view/schedule_work_card_screen.dart`), в окружении
/// соседних блоков — иначе не видно, попадает ли он в их язык.
///
/// Четыре случая подряд: два акта, один акт, дефектов нет, запрос не удался.
/// Данные подставные.
///
/// Запуск:
///
///     flutter run -t lib/dev/work_defects_block_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../foreman/defects/defect_entry.dart';
import '../foreman/defects/work_defects_block.dart';
import '../helper/class_colors.dart';
import '../screns/in_progress_works/models/work_details.dart';
import '../screns/in_progress_works/widgets/work_card_body.dart';

void main() {
  runApp(const WorkDefectsBlockPreviewApp());
}

class WorkDefectsBlockPreviewApp extends StatelessWidget {
  const WorkDefectsBlockPreviewApp({Key? key}) : super(key: key);

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
      theme: ThemeData(
        scaffoldBackgroundColor: ColorApp.myColorWhite,
        textTheme: GoogleFonts.ubuntuTextTheme(),
      ),
      home: const _PreviewPage(),
    );
  }
}

DefectEntry _entry({
  required int id,
  required String title,
  required DefectState state,
  DefectSource source = DefectSource.work,
  int photos = 0,
  int day = 14,
}) {
  return DefectEntry(
    id: id,
    title: title,
    source: source,
    state: state,
    createdAt: DateTime(2026, 8, day),
    photos: <DefectPhoto>[
      for (int i = 0; i < photos; i++)
        DefectPhoto(id: id * 100 + i, url: 'нет/файла'),
    ],
  );
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({Key? key}) : super(key: key);

  static const WorkChecklist _checklist = WorkChecklist(
    title: 'ТО 3',
    steps: <ChecklistStep>[
      ChecklistStep(id: 1, title: 'Проверка табличек', done: true),
      ChecklistStep(id: 2, title: 'Проверка площадок', done: true),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text(
          'Дефекты в карточке ТО — набросок',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ColorApp.kPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Caption('Два акта — в окружении соседних блоков'),
                _Card(
                  child: WorkDefectsBlock(
                    entries: <DefectEntry>[
                      _entry(
                        id: 11,
                        title: 'Течь редуктора лебёдки',
                        state: DefectState.issued,
                        photos: 3,
                        day: 14,
                      ),
                      _entry(
                        id: 12,
                        title: 'Не горит освещение кабины',
                        state: DefectState.created,
                        source: DefectSource.checklistStep,
                        day: 14,
                      ),
                    ],
                    onTap: (DefectEntry entry) {},
                  ),
                ),
                const SizedBox(height: 32.0),
                const _Caption('Один акт'),
                _Card(
                  child: WorkDefectsBlock(
                    entries: <DefectEntry>[
                      _entry(
                        id: 21,
                        title: 'Износ направляющих башмаков выше нормы',
                        state: DefectState.fixed,
                        photos: 1,
                        day: 3,
                      ),
                    ],
                    onTap: (DefectEntry entry) {},
                  ),
                ),
                const SizedBox(height: 32.0),
                const _Caption('Дефектов нет — блок остаётся на месте'),
                const _Card(child: WorkDefectsBlock(entries: <DefectEntry>[])),
                const SizedBox(height: 32.0),
                const _Caption('Запрос не удался — тоже не молчим'),
                _Card(
                  child: WorkDefectsBlock(
                    entries: const <DefectEntry>[],
                    failure: 'Ошибка сети',
                    onRetry: () {},
                  ),
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Кусок карточки работы: чек-лист сверху, блок дефектов, времена снизу.
///
/// Соседи здесь не для красоты: их кегли и отступы — то самое, во что блок
/// должен попасть.
class _Card extends StatelessWidget {
  const _Card({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.myColorWhite,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const WorkChecklistBlock(
            checklist: _PreviewPage._checklist,
            photos: WorkPhotos.empty,
          ),
          const SizedBox(height: 16.0),
          child,
          const SizedBox(height: 16.0),
          WorkTimesBlock(
            details: WorkDetails(
              id: 300,
              checklist: _PreviewPage._checklist,
              startedAt: DateTime(2026, 8, 14, 9, 10),
              finishedAt: DateTime(2026, 8, 14, 11, 40),
            ),
            isProblem: false,
            showFinished: true,
            note: 'Информация о выполнении работы',
          ),
        ],
      ),
    );
  }
}

/// Подпись над образцом — только для наброска, в приложение не идёт.
class _Caption extends StatelessWidget {
  const _Caption(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w300,
          color: ColorApp.myColorGray,
        ),
      ),
    );
  }
}
