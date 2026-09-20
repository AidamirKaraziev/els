import '../models/checklist_template.dart';
import 'templates_repository.dart';

/// Шаблоны без сети: четыре модели, у каждой свой набор видов ТО, у части
/// пар шаблона нет.
///
/// Правка здесь настоящая: сохранённый список остаётся до конца работы
/// экрана — иначе на фикстуре «Сохранить» отыгрывалось бы назад само, и
/// проверить редактор глазами было бы нечем.
class FixtureTemplatesRepository implements TemplatesRepository {
  FixtureTemplatesRepository({this.delay = const Duration(milliseconds: 200)}) {
    _typeActs = <int, Map<int, String>>{
      1: <int, String>{1: 'ТО 1', 2: 'ТО 3', 3: 'ТО 6', 4: 'ТО 12'},
      2: <int, String>{1: 'ТО 1', 2: 'ТО 3', 3: 'ТО 6'},
      3: <int, String>{1: 'ТО 1', 2: 'ТО 3', 3: 'ТО 6', 4: 'ТО 12'},
      4: <int, String>{1: 'ТО 1', 2: 'ТО 3', 3: 'ТО 6', 4: 'ТО 12', 5: 'ТО 4'},
    };
    _state = <int, Map<int, List<String>?>>{
      1: <int, List<String>?>{
        1: List<String>.of(_to1),
        2: List<String>.of(_to3),
        3: null,
        4: List<String>.of(_to12),
      },
      2: <int, List<String>?>{1: List<String>.of(_to1), 2: null, 3: null},
      3: <int, List<String>?>{
        1: List<String>.of(_to1),
        2: List<String>.of(_to3),
        3: List<String>.of(_to6),
        4: List<String>.of(_to12),
      },
      4: <int, List<String>?>{1: null, 2: null, 3: null, 4: null, 5: null},
    };
  }

  /// Задержка ответа. Без неё загрузку не видно вовсе.
  final Duration delay;

  static const List<TemplateModel> _models = <TemplateModel>[
    TemplateModel(id: 1, name: 'LIFT A388509'),
    TemplateModel(id: 2, name: 'ЩЛЗ-400'),
    TemplateModel(id: 3, name: 'OTIS Gen2'),
    TemplateModel(id: 4, name: 'KONE MonoSpace'),
  ];

  /// Модель → вид ТО → имя. Наборы у моделей разные: у ЩЛЗ-400 нет «ТО 12»,
  /// у KONE есть «ТО 4». Новые дописываются с id = max+1 по всем моделям,
  /// как это делает `POST /type-acts/`.
  late final Map<int, Map<int, String>> _typeActs;

  static const List<String> _to1 = <String>[
    'Осмотр машинного помещения',
    'Проверка освещения кабины и шахты',
    'Проверка работы кнопок вызова и приказа',
    'Проверка точности остановки кабины',
    'Проверка дверей шахты и кабины',
  ];

  static const List<String> _to3 = <String>[
    'Осмотр машинного помещения',
    'Проверка освещения кабины и шахты',
    'Проверка работы кнопок вызова и приказа',
    'Проверка точности остановки кабины',
    'Проверка дверей шахты и кабины',
    'Смазка направляющих кабины и противовеса',
    'Проверка натяжения тяговых канатов',
    'Проверка тормоза лебёдки',
  ];

  static const List<String> _to6 = <String>[
    'Осмотр машинного помещения',
    'Проверка освещения кабины и шахты',
    'Проверка работы кнопок вызова и приказа',
    'Проверка точности остановки кабины',
    'Проверка дверей шахты и кабины',
    'Смазка направляющих кабины и противовеса',
    'Проверка натяжения тяговых канатов',
    'Проверка тормоза лебёдки',
    'Проверка ловителей',
    'Проверка ограничителя скорости',
    'Проверка буферов в приямке',
  ];

  static const List<String> _to12 = <String>[
    'Осмотр машинного помещения',
    'Проверка освещения кабины и шахты',
    'Проверка работы кнопок вызова и приказа',
    'Проверка точности остановки кабины',
    'Проверка дверей шахты и кабины',
    'Смазка направляющих кабины и противовеса',
    'Проверка натяжения тяговых канатов',
    'Проверка тормоза лебёдки',
    'Проверка ловителей',
    'Проверка ограничителя скорости',
    'Проверка буферов в приямке',
    'Проверка изоляции электрооборудования',
    'Проверка заземления',
    'Испытание ловителей под нагрузкой',
  ];

  /// Модель → вид ТО → шаги; `null` — шаблона нет.
  late final Map<int, Map<int, List<String>?>> _state;

  /// Убранные виды по моделям — как `deleted_at` в `acts_bases`, только
  /// без даты. Шаги в `_state` при этом остаются.
  final Map<int, Set<int>> _deleted = <int, Set<int>>{};

  bool _isDeleted(int modelId, int typeActId) =>
      _deleted[modelId]?.contains(typeActId) ?? false;

  /// Живые виды в порядке справочника, убранные — за ними.
  @override
  Future<List<ModelTemplates>> loadAll() async {
    await _wait();
    return <ModelTemplates>[
      for (final TemplateModel model in _models)
        ModelTemplates(
          model: model,
          types: <TemplateTypeAct>[
            for (final MapEntry<int, String> act
                in _typeActs[model.id]!.entries)
              if (!_isDeleted(model.id, act.key))
                _typeAct(model.id, act.key, act.value),
            for (final MapEntry<int, String> act
                in _typeActs[model.id]!.entries)
              if (_isDeleted(model.id, act.key))
                _typeAct(model.id, act.key, act.value),
          ],
        ),
    ];
  }

  TemplateTypeAct _typeAct(int modelId, int typeActId, String name) {
    final List<String>? steps = _state[modelId]?[typeActId];
    return TemplateTypeAct(
      typeActId: typeActId,
      typeActName: name,
      templateId: steps == null ? null : modelId * 10 + typeActId,
      steps: steps == null ? const <String>[] : List<String>.unmodifiable(steps),
      deleted: _isDeleted(modelId, typeActId),
    );
  }

  @override
  Future<void> save({
    required int modelId,
    required int typeActId,
    required List<String> steps,
  }) async {
    await _wait();
    _state[modelId]![typeActId] = List<String>.of(steps);
  }

  @override
  Future<void> addTypeAct({required int modelId, required String name}) async {
    await _wait();
    final int id = _typeActs.values
            .expand((Map<int, String> byType) => byType.keys)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
    _typeActs[modelId]![id] = name;
    _state[modelId]![id] = null;
  }

  @override
  Future<void> removeTypeAct({
    required int modelId,
    required int typeActId,
  }) async {
    await _wait();
    _deleted.putIfAbsent(modelId, () => <int>{}).add(typeActId);
  }

  @override
  Future<void> restoreTypeAct({
    required int modelId,
    required int typeActId,
  }) async {
    await _wait();
    _deleted[modelId]?.remove(typeActId);
  }

  @override
  Future<List<TemplateSource>> sources() async {
    await _wait();
    return <TemplateSource>[
      for (final TemplateModel model in _models)
        for (final MapEntry<int, String> act in _typeActs[model.id]!.entries)
          if (_state[model.id]![act.key] != null &&
              !_isDeleted(model.id, act.key))
            TemplateSource(
              modelName: model.name,
              typeActName: act.value,
              steps: List<String>.unmodifiable(_state[model.id]![act.key]!),
            ),
    ];
  }

  Future<void> _wait() => Future<void>.delayed(delay);
}
