import '../../../foreman/schedule_foreman/schedule_screen_foreman.dart'
    as foreman_data;
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart' show myStream;
import '../../object/view/object_screen.dart' as admin_data;
import '../models/schedule_row.dart';
import '../schedule_page.dart' as to_data;
import 'schedule_object_opener.dart';

/// Открывает экран «График» в оболочке подрядчика.
///
/// Оболочка держит все экраны одним списком и показывает тот, чей номер лежит
/// в `IntTest.indexScreens` (у прораба — `indexScreensForeman`). Своего окна
/// у экрана нет, маршрут ему не подсунуть: номер и глобальные переменные —
/// единственный вход, и переписывать под это оболочку целиком мы не стали.
///
/// Номера сняты со списков экранов: у админа 12 — `SchedulePage`
/// (`home_page.dart`), у прораба 14 — `SchedulePageForeman`
/// (`home_foreman.dart`). Кнопка «назад» в обоих экранах ставит 1 — это как
/// раз «Графики», так что человек возвращается в ленту, а не в чужой раздел.
///
/// Импорты с префиксами: файлы подрядчика объявляют одноимённые глобальные
/// переменные (`openTestOne` и подобные), и без префикса они бы столкнулись.
class ShellScheduleObjectOpener extends ScheduleObjectOpener {
  const ShellScheduleObjectOpener.admin() : _foreman = false;

  const ShellScheduleObjectOpener.foreman() : _foreman = true;

  /// Номер экрана «График» в списке экранов админской оболочки.
  static const int _adminScreen = 12;

  /// То же у прораба — список свой, и номер другой.
  static const int _foremanScreen = 14;

  final bool _foreman;

  @override
  Future<void> open(ScheduleRow row) async {
    final int objectId = row.objectId;

    // Экран читает объект не из аргумента, а из `IntTest.pressHover`: на нём
    // завязаны все его кнопки, вплоть до создания графика на год.
    IntTest.pressHover = objectId;

    // Карточка объекта у ролей разная: админ читает `listSelectedObject`,
    // прораб — `listSelectedScheduleForeman`. Ручка при этом одна и та же.
    if (_foreman) {
      await foreman_data.getListScheduleInfoForeman(objectId);
    } else {
      await admin_data.getListObjectInfo(objectId);
    }

    // Остальные три — сами ленты ТО под карточкой. Прорабу их раньше не
    // грузили вовсе, и блок «Техническое обслуживание» у него оставался от
    // прошлого объекта; грузим обеим ролям.
    await to_data.getAllTemplateTOInIdObject(objectId);
    await to_data.getFactActListInIdObject(objectId);
    await to_data.getTOScheduleIdObject(objectId);

    // Сначала номер, потом сигнал: оболочка перерисовывается по событию и
    // читает номер уже в `build`. В обратном порядке первый кадр достаётся
    // прежнему экрану.
    if (_foreman) {
      IntTest.indexScreensForeman = _foremanScreen;
      myStream.add(IntTest.indexScreensForeman);
    } else {
      IntTest.indexScreens = _adminScreen;
      myStream.add(IntTest.indexScreens);
    }
  }
}
