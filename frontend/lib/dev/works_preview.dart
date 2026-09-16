import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/user_bloc/user_bloc.dart';
import '../foreman/defects/defect_entry.dart';
import '../foreman/defects/defects_repository.dart';
import '../screns/in_progress_works/models/order_details.dart';
import '../screns/in_progress_works/models/work_details.dart';
import '../screns/in_progress_works/repository/work_details_repository.dart';
import '../screns/works/repository/fixture_works_repository.dart';
import '../screns/works/view/works_screen.dart';

/// Отдельная точка входа: экран «Работы» на фикстуре, без сервера.
///
/// Нужна, пока набросок не утверждён: кадра в Figma нет, и смотреть вёрстку
/// через вход и оболочку с живой базой — долго и не про вёрстку.
///
/// Запуск:
///
///     flutter run -t lib/dev/works_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(WorksPreviewApp());
}

class WorksPreviewApp extends StatelessWidget {
  WorksPreviewApp({Key? key}) : super(key: key);

  /// Одна на превью: созданная в форме работа ложится в ту же ленту.
  final FixtureWorksRepository repository = FixtureWorksRepository();

  @override
  Widget build(BuildContext context) {
    // Профиль в шапке карточки читает `UserBloc`; даём пустой, без входа он
    // ничего не рисует. Выше `MaterialApp`, а не внутри `home`: карточка
    // открывается новым маршрутом, и провайдер из `home` ей не виден.
    return BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('ru', '')],
        theme: ThemeData(textTheme: GoogleFonts.ubuntuTextTheme()),
        // Меню — пустое: боковое меню тянет за собой вход в систему.
        home: WorksScreen(
          repository: repository,
          drawer: const Drawer(),
          canCreateWork: true,
          detailsRepository: const _FixtureDetailsRepository(),
          defectsRepository: const _FixtureDefectsRepository(),
        ),
      ),
    );
  }
}

/// Подробности работы без сервера: у каждого ТО один и тот же чек-лист с
/// отметками, у заявки — задание и категория. Времена считаются от id, чтобы
/// карточки не выглядели одинаково.
class _FixtureDetailsRepository extends WorkDetailsRepository {
  const _FixtureDetailsRepository();

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    final DateTime now = DateTime.now();
    // Сданные ТО в фикстуре — с id ниже 7700.
    final bool finished = actId < 7700;
    return WorkDetails(
      id: actId,
      checklist: const WorkChecklist(
        title: 'ТО',
        steps: <ChecklistStep>[
          ChecklistStep(
            id: 1,
            title: 'Проверка табличек и освещения',
            done: true,
          ),
          ChecklistStep(
            id: 2,
            title: 'Осмотр дверей шахты и кабины',
            done: true,
            comment: 'Ролик верхней створки с люфтом',
          ),
          ChecklistStep(id: 3, title: 'Проверка кнопок вызова', done: true),
          ChecklistStep(
            id: 4,
            title: 'Осмотр канатов',
            done: false,
            comment: 'Обрыв прядей на 3-м канате, нужна замена комплекта',
          ),
          ChecklistStep(id: 5, title: 'Проверка ловителей', done: false),
        ],
      ),
      startedAt: now.subtract(Duration(minutes: 40 + actId % 50)),
      finishedAt: finished ? now.subtract(const Duration(minutes: 5)) : null,
      mainMechanicId: 5,
    );
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async {
    // Снимки у каждого второго ТО: пункт с замечанием и пункт без него,
    // чтобы блок читался в обоих видах.
    if (actId.isEven) return WorkPhotos.empty;
    return WorkPhotos(<int, List<String>>{
      2: <String>[_photo('liftTest3.jpeg'), _photo('lift5.png')],
      4: <String>[_photo('escalator.png')],
    });
  }

  @override
  Future<OrderDetails> fetchOrder(int orderId) async {
    return OrderDetails(
      id: orderId,
      taskText: 'Лифт не закрывает двери на 3 этаже, жильцы жалуются',
      categoryName: 'Двери',
      reasonFault: 'Ролик створки',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      executor: const Performer(
        id: 5,
        name: 'Смирнов А.',
        phone: '+7 921 123-45-67',
      ),
    );
  }

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async {
    if (orderId % 3 == 0) return OrderPhotos.empty;
    return OrderPhotos(<String>[_photo('liftTest3.jpeg'), _photo('lift6.png')]);
  }

  @override
  Future<Performer> fetchPerformer(int userId) async => const Performer(
    id: 5,
    name: 'Смирнов А.',
    specialty: 'Механик',
    phone: '+7 921 123-45-67',
  );
}

/// Адрес снимка из бандла: dev-сервер Flutter раздаёт `assets/` рядом со
/// страницей, а [apiImage] ждёт полный адрес и без схемы дописывает свою —
/// относительный путь ему не подойдёт.
String _photo(String name) =>
    Uri.base.resolve('assets/assets/$name').toString();

/// Дефекты без сервера: явная карта «работа → акты», а не правило по id.
///
/// Работы с актами помечены `hasDefect` в [FixtureWorksRepository] — обе
/// фикстуры держим согласованными руками. Набор покрывает все виды работ и
/// все состояния акта: с фото и без, с описанием и без, ушедшие клиенту.
class _FixtureDefectsRepository extends DefectsRepository {
  const _FixtureDefectsRepository();

  static DefectEntry _act(
    int id, {
    required String title,
    required DefectSource source,
    DefectState state = DefectState.created,
    String? description,
    int daysAgo = 0,
    List<String> photos = const <String>[],
    bool issued = false,
  }) {
    final DateTime created = DateTime.now().subtract(Duration(days: daysAgo));
    return DefectEntry(
      id: id,
      title: title,
      source: source,
      state: state,
      description: description,
      createdAt: created,
      authorName: 'Смирнов А.',
      typeActName: source == DefectSource.order ? null : 'ТО-3',
      photos: <DefectPhoto>[
        for (int i = 0; i < photos.length; i++)
          DefectPhoto(id: id * 10 + i, url: _photo(photos[i])),
      ],
      clientActs: issued
          ? <DefectClientAct>[
              DefectClientAct(
                id: id * 100,
                title: title,
                pdfPath: 'defective_act/$id.pdf',
                createdAt: created.add(const Duration(days: 1)),
              ),
            ]
          : const <DefectClientAct>[],
    );
  }

  // --- ТО (act_fact) -------------------------------------------------------

  static List<DefectEntry> _byActFact(int actFactId) {
    switch (actFactId) {
      case 7715: // ТО в работе: два акта, пункт и работа целиком
        return <DefectEntry>[
          _act(
            77151,
            title: 'Износ ролика створки двери',
            source: DefectSource.checklistStep,
            description:
                'Ролик верхней створки с люфтом, требуется замена. '
                'Створка при закрытии подклинивает на середине хода.',
            photos: <String>['liftTest3.jpeg', 'lift5.png'],
          ),
          _act(
            77152,
            title: 'Подтёки масла на редукторе',
            source: DefectSource.work,
            state: DefectState.reviewed,
            daysAgo: 1,
          ),
        ];
      case 7690: // сданное ТО: акт уже ушёл клиенту
        return <DefectEntry>[
          _act(
            76901,
            title: 'Обрыв прядей каната',
            source: DefectSource.checklistStep,
            state: DefectState.issued,
            description: 'Обрыв прядей на 3-м канате, нужна замена комплекта.',
            daysAgo: 3,
            photos: <String>['escalator.png'],
            issued: true,
          ),
        ];
      default:
        return const <DefectEntry>[];
    }
  }

  // --- заявки (order) ------------------------------------------------------

  static List<DefectEntry> _byOrder(int orderId) {
    switch (orderId) {
      case 1042: // авария, новая: акт без описания и без фото
        return <DefectEntry>[
          _act(
            10421,
            title: 'Лифт стоит между этажами',
            source: DefectSource.order,
          ),
        ];
      case 1037: // авария в работе
        return <DefectEntry>[
          _act(
            10371,
            title: 'Обрыв цепи безопасности',
            source: DefectSource.order,
            description:
                'Заявка на скрип двери: при осмотре найден обрыв '
                'цепи безопасности верхней створки.',
            photos: <String>['liftTest3.jpeg'],
          ),
        ];
      case 1033: // обращение: два акта, один уже устранён
        return <DefectEntry>[
          _act(
            10331,
            title: 'Не горит освещение кабины',
            source: DefectSource.order,
            state: DefectState.fixed,
            description: 'Заменена лампа, проверено.',
            daysAgo: 2,
          ),
          _act(
            10332,
            title: 'Скрип при открытии дверей',
            source: DefectSource.order,
            state: DefectState.reviewed,
            description: 'Сухая направляющая, нужна смазка.',
            daysAgo: 1,
            photos: <String>['lift5.png', 'lift6.png'],
          ),
        ];
      case 1025: // обращение с проблемой: три снимка
        return <DefectEntry>[
          _act(
            10251,
            title: 'Кнопка вызова 5 этажа не работает',
            source: DefectSource.order,
            description: 'Кнопка залипает, вызов не проходит.',
            photos: <String>['liftTest3.jpeg', 'lift5.png', 'escalator.png'],
          ),
        ];
      case 1031: // заявка в работе: ушла клиенту
        return <DefectEntry>[
          _act(
            10311,
            title: 'Трещина в шкиве ограничителя скорости',
            source: DefectSource.order,
            state: DefectState.issued,
            description: 'Шкив под замену, лифт остановлен до замены.',
            daysAgo: 1,
            photos: <String>['liftTest3.jpeg'],
            issued: true,
          ),
        ];
      case 1035: // дефект, принят
        return <DefectEntry>[
          _act(
            10351,
            title: 'Износ канатов',
            source: DefectSource.order,
            description: 'Износ канатов, требуется замена комплекта.',
            photos: <String>['lift6.png'],
          ),
        ];
      case 1019: // дефект, сдан: два акта
        return <DefectEntry>[
          _act(
            10191,
            title: 'Люфт направляющих',
            source: DefectSource.order,
            state: DefectState.fixed,
            description: 'Направляющие отрегулированы.',
            daysAgo: 4,
            photos: <String>['liftTest3.jpeg', 'lift5.png'],
          ),
          _act(
            10192,
            title: 'Износ башмаков противовеса',
            source: DefectSource.order,
            state: DefectState.reviewed,
            daysAgo: 4,
          ),
        ];
      case 880: // дефект с проблемой
        return <DefectEntry>[
          _act(
            8801,
            title: 'Перегрев лебёдки',
            source: DefectSource.order,
            description:
                'Лебёдка греется после 20 минут работы, '
                'нужна диагностика привода.',
            daysAgo: 6,
            photos: <String>['escalator.png'],
          ),
        ];
      default:
        return const <DefectEntry>[];
    }
  }

  @override
  Future<List<DefectEntry>> byActFact(int actFactId) async =>
      _byActFact(actFactId);

  @override
  Future<List<DefectEntry>> byOrder(int orderId) async => _byOrder(orderId);

  /// Карточка дозапрашивает акт по id; ищем по всем спискам подряд.
  @override
  Future<DefectEntry> byId(int id) async {
    const List<int> works = <int>[7715, 7690];
    const List<int> orders = <int>[
      1042,
      1037,
      1033,
      1025,
      1031,
      1035,
      1019,
      880,
    ];
    return <DefectEntry>[
      for (final int w in works) ..._byActFact(w),
      for (final int o in orders) ..._byOrder(o),
    ].firstWhere((DefectEntry e) => e.id == id);
  }
}
