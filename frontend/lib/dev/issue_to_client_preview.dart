/// Набросок экрана «Оформить клиенту» — вид без сервера и без входа.
///
/// Кадра в макете нет: вёрстка утверждена по картинке-наброску, и здесь она
/// собрана на Flutter, чтобы смотреть её живьём — с клавиатурой, длинными
/// текстами и настоящими нажатиями по галочкам. Сети нет: снимки не грузятся,
/// на их месте остаётся пустая плитка, галочки при этом работают.
///
/// У снимков пустой путь: `apiImage` рисует такой прозрачным пикселем и в
/// сеть не идёт. В наброске остаётся рамка с галочкой — ровно то, что здесь
/// и проверяется; настоящие фотографии смотрим на собранном стеке.
///
/// Кнопка ничего не отправляет — черновик показывается снизу экрана, ровно
/// тот, что ушёл бы в `POST /defective-act/{id}/issue-to-client/`.
///
/// Запуск:
///
///     flutter run -t lib/dev/issue_to_client_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../foreman/defects/defect_entry.dart';
import '../foreman/defects/issue_to_client_screen.dart';
import '../helper/class_colors.dart';

void main() {
  runApp(const IssueToClientPreviewApp());
}

class IssueToClientPreviewApp extends StatelessWidget {
  const IssueToClientPreviewApp({Key? key}) : super(key: key);

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
        scaffoldBackgroundColor: ColorApp.myColorTransparent,
        textTheme: GoogleFonts.ubuntuTextTheme(),
      ),
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome();

  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  IssueDraft? _last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: IssueToClientScreen(
            entry: _entry,
            onIssue: (IssueDraft draft) async {
              setState(() => _last = draft);
            },
          ),
        ),
        _DraftBar(draft: _last),
      ],
    );
  }
}

/// Что ушло бы на сервер. В приложении такой полосы нет — она только здесь,
/// чтобы набросок было чем проверить без сети.
class _DraftBar extends StatelessWidget {
  const _DraftBar({required this.draft});

  final IssueDraft? draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xff1E1E1E),
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
      child: Text(
        draft == null
            ? 'Нажмите «Сформировать PDF» — здесь появится тело запроса.'
            : draft!.toBody().toString(),
        style: const TextStyle(
          fontSize: 12.0,
          height: 1.5,
          color: Color(0xffD7D7D7),
        ),
      ),
    );
  }
}

/// Дефект с полным набором: три снимка, описание, вид ТО — чтобы на экране
/// было что выбирать и что подставлять в подсказки.
final DefectEntry _entry = DefectEntry(
  id: 12,
  title: 'Износ тягового каната сверх нормы',
  description:
      'На пункте 14 замерен износ тягового каната: 8% против допустимых 5%. '
      'Канат требует замены до следующего планового ТО.',
  source: DefectSource.checklistStep,
  state: DefectState.created,
  createdAt: DateTime(2026, 9, 3),
  month: 9,
  year: '2026',
  typeActName: 'ТО-1',
  authorName: 'Закора Андрей А',
  objectName: 'Эскалатор 2а «Лакоста»',
  photos: const <DefectPhoto>[
    DefectPhoto(id: 1, url: ''),
    DefectPhoto(id: 2, url: ''),
    DefectPhoto(id: 3, url: ''),
  ],
);
