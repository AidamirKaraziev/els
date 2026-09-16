import '../models/new_work_draft.dart';
import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_section.dart';

/// Ошибка, которую можно показать человеку: короткий текст без кодов.
class WorksException implements Exception {
  const WorksException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Ответ ленты: строки под отбор, числа для чипсов и справочники для
/// выпадашек. Один в один `WorkFeed` из `backend/src/schemas/work_feed.py`.
class WorksFeed {
  const WorksFeed({
    required this.items,
    required this.counts,
    this.attentionCount = 0,
    this.nextCursor,
    this.sections = const <WorkSection>[],
    this.employees = const <WorkEmployee>[],
    this.mySections = const <int>{},
  });

  final List<WorkItem> items;
  final WorkCounts counts;

  /// Сколько строк требуют внимания — по всему отбору, не по странице. При
  /// порядке [WorkSort.attention] ровно столько первых строк [items] — блок
  /// внимания (пока страница одна); при [WorkSort.updated] — ноль.
  final int attentionCount;

  /// Курсор следующей страницы; `null` — страница последняя.
  final String? nextCursor;

  /// Участки, что встречаются в ленте, — для выпадашки.
  final List<WorkSection> sections;

  /// Кого можно назначить — с должностью и участком. Они же — выпадашка
  /// «Механик».
  final List<WorkEmployee> employees;

  /// Участки прораба — под чипс «Мои участки».
  final Set<int> mySections;

  WorksFeed copyWith({
    List<WorkItem>? items,
    WorkCounts? counts,
    int? attentionCount,
    String? nextCursor,
    bool clearCursor = false,
    List<WorkSection>? sections,
    List<WorkEmployee>? employees,
    Set<int>? mySections,
  }) {
    return WorksFeed(
      items: items ?? this.items,
      counts: counts ?? this.counts,
      attentionCount: attentionCount ?? this.attentionCount,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      sections: sections ?? this.sections,
      employees: employees ?? this.employees,
      mySections: mySections ?? this.mySections,
    );
  }
}

/// Откуда лента берёт работы.
///
/// Две реализации: фикстура для превью и тестов, сеть поверх ручки
/// `GET /work/feed`. Контракт нарочно узкий — отбор целиком туда, строки и
/// счётчики обратно, — чтобы экран не знал, откуда что приехало.
abstract class WorksRepository {
  /// Страница ленты. [cursor] — из прошлого ответа; [limit] — сколько строк,
  /// `1` — когда нужны только счётчики и справочники.
  Future<WorksFeed> fetch(WorkFilters filters, {String? cursor, int? limit});

  /// Что изменилось после [since] под **широким** отбором
  /// ([WorkFilters.wide]) — включая архивные (`isActual == false`). Строку,
  /// что ушла из-под чипса, лента убирает сама по [WorkFilters.matches].
  Future<List<WorkItem>> changes(WorkFilters filters, DateTime since);

  /// Назначить сотрудника на заявку. Новая становится принятой. Отдаёт
  /// строку, какой она стала.
  Future<WorkItem> assign(WorkItem item, WorkEmployee who);

  /// Прораб посмотрел: строка уходит из блока внимания. Отдаёт строку.
  Future<WorkItem> review(WorkItem item);

  /// Сколько сданных работ ещё не просмотрено — число на бейдж у пункта
  /// «Работы» в бургере. Считается по всему, что видно человеку, а не по
  /// странице на руках: на ней может не быть ни одной сданной.
  Future<int> unreviewedCount();

  /// Справочники для формы «Новая работа»: объекты, категории, кого можно
  /// назначить, что уже висит по объектам. Спрашивается при открытии формы,
  /// а не вместе с лентой: объектов сотни, а форму открывают не каждый раз.
  Future<NewWorkContext> newWorkContext();

  /// Завести работу. Отдаёт номер созданной заявки — для «Работа №N создана».
  /// Ошибка словами — [WorksException]; форма показывает её и остаётся.
  Future<int> createWork(NewWorkDraft draft);
}
