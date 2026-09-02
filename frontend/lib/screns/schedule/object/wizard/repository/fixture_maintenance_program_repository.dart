import '../models/maintenance_program.dart';
import 'maintenance_program_repository.dart';

/// Программа модели без сети: тот же интерфейс поверх списка в памяти.
///
/// Правка здесь настоящая: сохранённая программа остаётся сохранённой до
/// конца работы экрана — иначе на фикстуре «Сохранить» отыгрывалось бы назад
/// само, и проверить окно глазами было бы нечем.
class FixtureMaintenanceProgramRepository implements MaintenanceProgramRepository {
  FixtureMaintenanceProgramRepository({
    this.withProgram = true,
    this.delay = const Duration(milliseconds: 200),
  });

  /// Заведена ли у модели программа. `false` — тот случай, ради которого в
  /// предпросмотре есть строка «программа не заведена».
  final bool withProgram;

  /// Задержка ответа. Без неё загрузку не видно вовсе.
  final Duration delay;

  /// Что сохранили последним. `null` — ещё не сохраняли.
  MaintenanceProgram? saved;

  /// Программа со скриншота: ТО 12 раз в год, ТО 6 в середине, ТО 3 дважды.
  static const List<int> _defaultPositions = <int>[
    1, 1, 2, 1, 1, 3, 1, 1, 2, 1, 1, 4,
  ];

  static const List<TypeAct> _typeActs = <TypeAct>[
    TypeAct(id: 1, name: 'ТО 1'),
    TypeAct(id: 2, name: 'ТО 3'),
    TypeAct(id: 3, name: 'ТО 6'),
    TypeAct(id: 4, name: 'ТО 12'),
  ];

  @override
  Future<MaintenanceProgram?> program(int modelId) async {
    await _wait();
    final MaintenanceProgram? stored = saved;
    if (stored != null) return stored;
    if (!withProgram) return null;
    return _byPositions(modelId, _defaultPositions);
  }

  @override
  Future<MaintenanceProgram> suggestion(int modelId) async {
    await _wait();
    return _byPositions(modelId, _defaultPositions);
  }

  @override
  Future<List<TypeAct>> typeActs() async {
    await _wait();
    return _typeActs;
  }

  @override
  Future<void> save(MaintenanceProgram program) async {
    await _wait();
    saved = program;
  }

  MaintenanceProgram _byPositions(int modelId, List<int> ids) {
    return MaintenanceProgram(
      modelId: modelId,
      name: 'LIFT A388509',
      items: <MaintenanceProgramItem>[
        for (int position = 1; position <= kProgramLength; position++)
          MaintenanceProgramItem(
            position: position,
            typeActId: ids[position - 1],
            typeActName: _nameOf(ids[position - 1]),
          ),
      ],
    );
  }

  static String _nameOf(int id) =>
      _typeActs.firstWhere((TypeAct act) => act.id == id).name;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }
}
