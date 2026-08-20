/// Чек-лист фактического акта — то, чего нет в списке ТО.
///
/// `GET /act-fact/for-me` чек-лист наружу не отдаёт: строка регламента весит
/// сотни килобайт, и список из тридцати ТО с ней бы не открылся. В списке
/// приходит только «сделано N из M», а сами пункты — по адресу конкретного
/// акта, `GET /act-fact/{id}/`. Поэтому у ТО два источника, и делят они
/// обязанности так:
///
/// * **строка списка** (`LocalCollection.maintenance`) — объект, срок,
///   `started_at`, `finished_at`, `steps_done`; всё это целые секунды эпохи и
///   всё это уже лежит на телефоне;
/// * **[ActDetails]** (`LocalCollection.acts`) — только пункты регламента.
///
/// Даты сознательно берутся из строки списка, а не отсюда: в ответе акта они
/// приезжают строкой ISO, в списке — числом, и держать два представления
/// одного времени значит рано или поздно показать человеку разное в списке и
/// в карточке.
///
/// **Чек-лист отправляется целиком.** `PUT /act-fact/{id}/` принимает
/// `checklist` полностью — отметка пункта и правка списка на бэкенде одно и
/// то же действие. Номер шага при этом стабилен: на него ссылается
/// фотография, поэтому пункт без `id` считается новым и снимки старого к нему
/// не перейдут.
library;

import 'tasks.dart';

/// Пункт регламента.
class ActStep {
  const ActStep({
    required this.id,
    required this.title,
    this.done = false,
    this.comment,
  });

  /// Номер шага внутри акта. `null` — пункта ещё нет на сервере; такой мы
  /// сами не заводим, но в ответе он теоретически возможен.
  final int? id;

  final String title;
  final bool done;
  final String? comment;

  ActStep copyWith({bool? done, String? comment}) {
    return ActStep(
      id: id,
      title: title,
      done: done ?? this.done,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toBody() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'title': title,
      'done': done,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
    };
  }
}

/// Акт глазами механика: название регламента и его пункты.
class ActDetails {
  const ActDetails({
    required this.id,
    this.title,
    this.steps = const <ActStep>[],
  });

  final int id;

  /// Название ТО из графика, например «ТО-1». Может отсутствовать.
  final String? title;

  final List<ActStep> steps;

  int get total => steps.length;

  int get doneCount => steps.where((ActStep step) => step.done).length;

  /// Пустой чек-лист означает «регламент не заполнен», а не «работ не было».
  /// Проходить в таком акте нечего, и экран шагов об этом говорит прямо.
  bool get empty => steps.isEmpty;

  ActDetails withStepAt(int index, ActStep step) {
    if (index < 0 || index >= steps.length) return this;
    final List<ActStep> next = List<ActStep>.of(steps);
    next[index] = step;
    return ActDetails(id: id, title: title, steps: next);
  }

  /// Тело для `PUT /act-fact/{id}/`: чек-лист целиком.
  Map<String, dynamic> checklistBody() {
    return <String, dynamic>{
      if (title != null) 'title': title,
      'steps': steps.map((ActStep step) => step.toBody()).toList(),
    };
  }

  /// Строка для локальной базы — в той же форме, в какой её отдаёт бэкенд.
  /// Так синхронизация и локальная отметка пишут одно и то же.
  Map<String, dynamic> toRow() {
    return <String, dynamic>{
      'id': id,
      'checklist': <String, dynamic>{
        if (title != null) 'title': title,
        'steps': steps.map((ActStep step) => step.toBody()).toList(),
      },
    };
  }
}

/// Разбор ответа `GET /act-fact/{id}/` и строки локальной базы — форма у них
/// одна и та же.
ActDetails actFromRow(Map<String, dynamic> row) {
  final Map<String, dynamic> checklist = asMap(row['checklist']);
  final Object? steps = checklist['steps'];

  return ActDetails(
    id: asInt(row['id']) ?? 0,
    title: asString(checklist['title']),
    steps: steps is! List
        ? const <ActStep>[]
        : steps
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> raw) => raw.cast<String, dynamic>())
            .map(_stepFromRow)
            .whereType<ActStep>()
            .toList(),
  );
}

ActStep? _stepFromRow(Map<String, dynamic> row) {
  final String? title = asString(row['title']);
  if (title == null) return null;
  return ActStep(
    id: asInt(row['id']),
    title: title,
    done: row['done'] == true,
    comment: asString(row['comment']),
  );
}

/// «5 из 8» — подпись прогресса, одинаковая в списке, карточке и шапке шагов.
String progressText(int done, int total) => '$done из $total';
