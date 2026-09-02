import '../../models/month_cell.dart';
import '../models/schedule_object_card.dart';
import '../models/schedule_responsible.dart';
import 'schedule_object_repository.dart';

/// Карточка объекта и его лента из кадра макета, без сети.
///
/// Нужна, пока внешний вид не утверждён: экран должен открываться где угодно
/// — в браузере с отдельной точки входа, в виджет-тесте — не требуя ни входа
/// в систему, ни живой базы.
///
/// Значения взяты с кадра `1182:232` дословно, включая опечатки в кавычках:
/// сверять вёрстку удобнее с тем же текстом, что на картинке.
class FixtureScheduleObjectRepository implements ScheduleObjectRepository {
  FixtureScheduleObjectRepository({this.delay = Duration.zero, int? filledYear})
      : _filledYear = filledYear ?? DateTime.now().year;

  /// Задержка ответа. По умолчанию мгновенно; ненулевая нужна, только чтобы
  /// посмотреть глазами состояние загрузки.
  final Duration delay;

  /// Год, на котором лента заполнена. Остальные годы пустые — так на фикстуре
  /// видно оба случая сразу: текущий год с работой и соседний без графика.
  final int _filledYear;

  /// Годы, расставленные кнопкой «Создать график». Живут только в памяти:
  /// фикстуре достаточно показать, что после создания лента перерисовалась.
  final Map<int, List<MonthCell>> _generated = <int, List<MonthCell>>{};

  /// Ленты годов, которые уже показывали. Живут в памяти: сюда ложится
  /// перенос ТО, чтобы он пережил перечитывание ленты.
  final Map<int, List<MonthCell>> _years = <int, List<MonthCell>>{};

  /// Программа обслуживания модели: двенадцать позиций по кругу. Та же, что
  /// в примере плана — `ТО1, ТО1, ТО3, ТО1, ТО1, ТО6, …`.
  static const List<int> _program = <int>[1, 1, 3, 1, 1, 6, 1, 1, 3, 1, 1, 12];

  @override
  Future<ScheduleObjectCard> fetchCard(int objectId) async {
    await _wait();
    return ScheduleObjectCard(
      id: objectId,
      organization: 'ООО «КПЭК»',
      division: 'Северная/Тургенева',
      address: 'г. Краснодар, ул. Северная, 356',
      type: 'Лифт',
      model: 'LIFT A388509',
      registrationNumber: '23834939003928282',
      factoryNumber: '23834939003928282',
      company: 'ООО "Гармония"',
      contactPerson: 'П.С. Василенко',
      contactPhone: '+7 (918) 456-78-90',
      contract: 'Договор №2123 от 24.04.2022',
      // Точка на кадре — центр Краснодара, там же стоит маркер.
      geo: const ScheduleGeoPoint(45.035470, 38.975313),
      foreman: const ScheduleResponsible(
        title: 'Прораб',
        fullName: 'Н.В. Гоголевский',
        id: 12,
      ),
      mechanic: const ScheduleResponsible(
        title: 'Механик',
        fullName: 'Л.А. Терешков',
        id: 34,
      ),
    );
  }

  @override
  Future<List<MonthCell>> fetchYear(int objectId, int year) async {
    await _wait();
    return _year(year);
  }

  @override
  Future<void> moveCell(
    int objectId,
    int year, {
    required int actId,
    required int fromMonth,
    required int toMonth,
  }) async {
    await _wait();
    final List<MonthCell> cells = _year(year);
    final MonthCell from = cells[fromMonth - 1];
    // Как на сервере: план меняется, сама работа — нет. Вид ТО и акт едут за
    // клеткой, состояние пересчитывается по новому месяцу.
    cells[toMonth - 1] = MonthCell(
      month: toMonth,
      status: _statusFor(year, toMonth),
      toName: from.toName,
      actId: from.actId,
    );
    cells[fromMonth - 1] = MonthCell.empty(fromMonth);
  }

  /// Лента года, одна и та же от вызова к вызову.
  ///
  /// Держим её списком в памяти, а не собираем заново: перенос ТО должен
  /// оставаться на месте после перечитывания ленты, иначе на фикстуре
  /// перетаскивание отыгрывалось бы назад само.
  List<MonthCell> _year(int year) {
    return _years.putIfAbsent(year, () {
      final List<MonthCell>? generated = _generated[year];
      if (generated != null) return List<MonthCell>.of(generated);
      if (year != _filledYear) {
        return <MonthCell>[
          for (int month = 1; month <= 12; month++) MonthCell.empty(month)
        ];
      }
      return _filled();
    });
  }

  /// Назначено или просрочено — по тому, кончился ли месяц. Ровно так же
  /// считает сервер, и перенесённое ТО обязано слушаться того же правила.
  MonthStatus _statusFor(int year, int month) {
    final DateTime now = DateTime.now();
    final bool past = year < now.year || (year == now.year && month < now.month);
    return past ? MonthStatus.overdue : MonthStatus.pending;
  }

  @override
  @Deprecated(
    'График расставляет мастер: ScheduleWizardRepository.generate шлёт '
    'выбранный месяц. Метод оставлен живым — он в проде.',
  )
  Future<void> generateYear(int objectId, int year) async {
    await _wait();
    // Как на сервере: акты созданы, но ни один не закрыт. Значит прошедшие
    // месяцы сразу просрочены, а будущие ждут своего срока.
    final int nowMonth = DateTime.now().month;
    final bool isCurrentYear = year == DateTime.now().year;
    _generated[year] = <MonthCell>[
      for (int month = 1; month <= 12; month++)
        MonthCell(
          month: month,
          status: isCurrentYear && month < nowMonth
              ? MonthStatus.overdue
              : MonthStatus.pending,
          toName: 'ТО ${_program[month - 1]}',
          actId: 1000 + month,
        ),
    ];
    // Расстановка отменяет то, что лежало в памяти за этот год: иначе лента
    // осталась бы прежней, пустой.
    _years.remove(year);
  }

  /// Заполненный год: все пять состояний разом, иначе цвета ленты глазами не
  /// проверить. Одиннадцатый месяц оставлен пустым — так бывает и в базе,
  /// когда акт удалили.
  List<MonthCell> _filled() {
    const List<MonthStatus> statuses = <MonthStatus>[
      MonthStatus.done,
      MonthStatus.done,
      MonthStatus.late,
      MonthStatus.done,
      MonthStatus.overdue,
      MonthStatus.done,
      MonthStatus.done,
      MonthStatus.late,
      MonthStatus.pending,
      MonthStatus.pending,
      MonthStatus.none,
      MonthStatus.pending,
    ];

    return <MonthCell>[
      for (int month = 1; month <= 12; month++)
        if (statuses[month - 1] == MonthStatus.none)
          MonthCell.empty(month)
        else
          MonthCell(
            month: month,
            status: statuses[month - 1],
            toName: 'ТО ${_program[month - 1]}',
            actId: 100 + month,
          ),
    ];
  }

  Future<void> _wait() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }
}
