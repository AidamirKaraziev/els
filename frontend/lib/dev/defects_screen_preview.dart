/// Набросок экранов дефектов прораба — вид без сервера и без входа.
///
/// Кадра в макете нет, поэтому набросок показывается отдельно на утверждение,
/// по правилу «макет утверждается до логики». Вёрстка собрана из приёмов
/// карточки объекта прораба и списков механика — см. `defects_layout.dart`.
///
/// Дефекты здесь подставные и подобраны так, чтобы было видно все случаи:
/// четыре точки входа, четыре состояния, дефект без описания и без снимков,
/// длинный заголовок. Снимки не грузятся — в наброске сети нет, и на их
/// месте останется пустая плитка; галерею смотреть на живых данных.
///
/// Запуск:
///
///     flutter run -t lib/dev/defects_screen_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../foreman/defects/defect_entry.dart';
import '../foreman/defects/defects_screen.dart';
import '../helper/class_colors.dart';

void main() {
  runApp(const DefectsPreviewApp());
}

class DefectsPreviewApp extends StatelessWidget {
  const DefectsPreviewApp({Key? key}) : super(key: key);

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
      home: DefectsScreen(
        objectId: 44,
        objectName: 'Эскалатор 2а «Лакоста»',
        entries: _entries,
        today: DateTime(2026, 9, 5),
      ),
    );
  }
}

final List<DefectEntry> _entries = <DefectEntry>[
  // Дефект с пункта чек-листа: самая полная строка — есть всё.
  DefectEntry(
    id: 12,
    title: 'Износ тягового каната сверх нормы',
    description:
        'На пункте 14 замерен износ тягового каната: 8% против допустимых 5%. '
        'Канат требует замены до следующего планового ТО. Работу остановил, '
        'кабину зафиксировал на первом этаже.',
    source: DefectSource.checklistStep,
    state: DefectState.created,
    createdAt: DateTime(2026, 9, 3),
    month: 9,
    year: '2026',
    typeActName: 'ТО-1',
    authorName: 'Закора Андрей А',
    objectName: 'Эскалатор 2а «Лакоста»',
    photos: const <DefectPhoto>[
      DefectPhoto(id: 1, url: 'localhost/api/v1/static/demo-1.jpg'),
      DefectPhoto(id: 2, url: 'localhost/api/v1/static/demo-2.jpg'),
      DefectPhoto(id: 3, url: 'localhost/api/v1/static/demo-3.jpg'),
    ],
  ),
  // Дефект по работе целиком: пункта нет, вид ТО есть.
  DefectEntry(
    id: 11,
    title: 'Не фиксируется дверь шахты на третьем этаже',
    description:
        'Замок двери шахты не доходит до защёлки, дверь отжимается рукой.',
    source: DefectSource.work,
    state: DefectState.reviewed,
    createdAt: DateTime(2026, 8, 21),
    month: 8,
    year: '2026',
    typeActName: 'ТО-2',
    authorName: 'Голдобин Сергей Генадьевич',
    objectName: 'Эскалатор 2а «Лакоста»',
    photos: const <DefectPhoto>[
      DefectPhoto(id: 4, url: 'localhost/api/v1/static/demo-4.jpg'),
    ],
  ),
  // Дефект по заявке: вида ТО нет — работы по ТО не было вовсе.
  DefectEntry(
    id: 9,
    title: 'Посторонний шум в редукторе при подъёме',
    description:
        'Выехал по аварийной заявке. Шум появляется под нагрузкой выше '
        'половины, на спуске не слышен.',
    source: DefectSource.order,
    state: DefectState.issued,
    createdAt: DateTime(2026, 7, 14),
    authorName: 'Самохвалов Артём Сергеевич',
    objectName: 'Эскалатор 2а «Лакоста»',
    photos: const <DefectPhoto>[
      DefectPhoto(id: 5, url: 'localhost/api/v1/static/demo-5.jpg'),
      DefectPhoto(id: 6, url: 'localhost/api/v1/static/demo-6.jpg'),
    ],
  ),
  // Заведён прямо с объекта, без описания и без снимков: так строка
  // выглядит, когда механик записал одну строку на ходу.
  DefectEntry(
    id: 7,
    title: 'Разбит плафон освещения кабины',
    source: DefectSource.object,
    state: DefectState.fixed,
    createdAt: DateTime(2026, 5, 19),
    authorName: 'Разумовский Лев Сергеевич',
  ),
  // Прошлый год — чтобы переключатель года в наброске было на чём проверить.
  DefectEntry(
    id: 2,
    title: 'Люфт в креплении башмака кабины',
    description: 'Устранено при следующем ТО, башмак подтянут.',
    source: DefectSource.work,
    state: DefectState.fixed,
    createdAt: DateTime(2025, 11, 8),
    month: 11,
    year: '2025',
    typeActName: 'ТО-1',
    authorName: 'Черкасский Владимер Владимирович',
    objectName: 'Эскалатор 2а «Лакоста»',
  ),
  // Длинный заголовок: проверяем, что строка не разъезжается.
  DefectEntry(
    id: 4,
    title: 'Коррозия направляющих противовеса на участке между вторым и '
        'третьим этажами, требуется зачистка и окраска',
    description: 'Очаговая коррозия, глубина до 0,5 мм.',
    source: DefectSource.work,
    state: DefectState.created,
    createdAt: DateTime(2026, 3, 2),
    month: 3,
    year: '2026',
    typeActName: 'ТО-3',
    authorName: 'Заряжайлов Сергей Николаевич',
    objectName: 'Эскалатор 2а «Лакоста»',
  ),
];
