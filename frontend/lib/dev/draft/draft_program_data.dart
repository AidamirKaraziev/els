import '../../screns/schedule/object/wizard/models/schedule_wizard_data.dart';

/// Данные наброска «Программа модели» — только для dev-точки.
///
/// Набросок утверждается глазами, поэтому сети здесь нет вовсе: программа
/// живёт в памяти экрана, а клетки года пересчитываются из неё на лету —
/// ровно так, как их считает `GET /planned-to/preview/` на бэкенде.
///
/// Классы клеток и позиций берём готовые из
/// `wizard/models/schedule_wizard_data.dart`: когда набросок переедет в бой,
/// разбор ответа ляжет в те же поля и переверстывать не придётся.

/// Расклад, который открывают с экрана выбора.
enum DraftFixture {
  /// Программа заведена целиком — обычный случай.
  ready,

  /// У модели программы нет: расставлять нечего, пока её не создали.
  missing,

  /// Программа есть, но у одной позиции не выбран вид ТО.
  incomplete,
}

extension DraftFixtureTitle on DraftFixture {
  String get title {
    switch (this) {
      case DraftFixture.ready:
        return 'Программа заведена';
      case DraftFixture.missing:
        return 'Программы у модели нет';
      case DraftFixture.incomplete:
        return 'В программе есть позиция без вида ТО';
    }
  }
}

/// Виды ТО, заведённые в справочнике. Список правится в памяти: «Добавить
/// вид ТО» дописывает сюда, и он тут же появляется в выборе позиции.
const List<String> kDraftTypeActs = <String>[
  'ТО 1',
  'ТО 3',
  'ТО 6',
  'ТО 12',
];

/// Марка и модель лифта — из карточки объекта.
///
/// Название программы начинается с них, и правке они не подлежат: программа
/// принадлежит модели, и назвать её чужим именем значит потерять, к чему она
/// относится.
const String kDraftModelName = 'LIFT A388509';

/// Программа модели в правке — двенадцать позиций цикла и название.
///
/// Изменяемая: набросок показывает, каково это — таскать позиции, а
/// неизменяемый список пришлось бы копировать на каждое движение.
class DraftProgram {
  DraftProgram({
    required this.modelName,
    this.note = '',
    required List<String> positions,
  }) : positions = List<String>.of(positions);

  /// Копия — окно правит свою, а страница принимает её только по «Сохранить».
  DraftProgram copy() =>
      DraftProgram(modelName: modelName, note: note, positions: positions);

  /// Марка и модель лифта, подтянутые из объекта. Только показ.
  final String modelName;

  /// Свободное дополнение к названию — то, что человек дописывает сам.
  String note;

  /// Название целиком: марка с моделью, а за ними — дописанное.
  String get name => note.isEmpty ? modelName : '$modelName — $note';

  /// Двенадцать видов ТО по позициям цикла. Пустая строка — вид не выбран.
  final List<String> positions;

  bool get hasEmptyPosition => positions.any((String name) => name.isEmpty);

  /// Позиции в том виде, в каком их ждёт боевой мастер.
  List<WizardProgramItem> get items => <WizardProgramItem>[
        for (int i = 0; i < positions.length; i++)
          WizardProgramItem(position: i + 1, typeActName: positions[i]),
      ];
}

/// Программа со скриншота: ТО 12 раз в год, ТО 6 в середине, ТО 3 дважды.
const List<String> _defaultPositions = <String>[
  'ТО 1',
  'ТО 1',
  'ТО 3',
  'ТО 1',
  'ТО 1',
  'ТО 6',
  'ТО 1',
  'ТО 1',
  'ТО 3',
  'ТО 1',
  'ТО 1',
  'ТО 12',
];

DraftProgram? buildDraftProgram(DraftFixture fixture) {
  switch (fixture) {
    case DraftFixture.missing:
      return null;
    case DraftFixture.ready:
      return DraftProgram(
        modelName: kDraftModelName,
        positions: _defaultPositions,
      );
    case DraftFixture.incomplete:
      final List<String> positions = List<String>.of(_defaultPositions);
      positions[5] = '';
      return DraftProgram(modelName: kDraftModelName, positions: positions);
  }
}

/// Месяцы, уже занятые актом: расстановка их не тронет.
const List<int> kDraftOccupiedMonths = <int>[];

/// Двенадцать клеток года по программе и месяцу начала цикла.
///
/// Позиция месяца считается от якоря по кругу: при старте в марте позиция 1
/// приходится на март, а январь получает одиннадцатую.
List<WizardPreviewCell> buildDraftCells({
  required DraftProgram program,
  required int anchorMonth,
}) {
  return <WizardPreviewCell>[
    for (int month = 1; month <= 12; month++)
      () {
        final int position = (month - anchorMonth + 12) % 12 + 1;
        final String typeActName = program.positions[position - 1];
        return WizardPreviewCell(
          month: month,
          position: position,
          typeActName: typeActName.isEmpty ? 'вид ТО не выбран' : typeActName,
          occupied: kDraftOccupiedMonths.contains(month),
          // Позиция без вида ТО — тот же янтарь, что и «нет шаблона»: и то и
          // другое означает «утвердить нельзя, пока не поправите».
          templateMissing: typeActName.isEmpty,
        );
      }(),
  ];
}
