/// Переход между разделами оболочки — одним местом на весь проект.
///
/// Оболочка подрядчика переключается тремя строками подряд: индекс экрана,
/// заголовок и событие в `myStream`. Забыть любую — и раздел либо не
/// сменится, либо сменится без подсветки пункта меню. Идиома взята из
/// `helper/my_drawer/my_drawer.dart`; второго способа переключать разделы
/// заводить нельзя — подсветка меню читает то же `IntTest.indexScreens`.
library;

import '../screns/home_page/home_page.dart';
import '../screns/schedule/models/schedule_filters.dart';
import '../screns/schedule/view/schedule_section.dart';
import 'class_colors.dart';

/// Индекс «Графиков» в списке экранов `home_page.dart`.
const int _schedulesIndex = 1;

/// Открыть раздел «Графики».
///
/// С [filters] лента откроется с этим отбором — так с главной уходит клик по
/// участку в карточке «Выполнение графика». Без них раздел покажет то же, что
/// и переход из меню: все объекты за текущий год.
void openSchedules({ScheduleFilters? filters}) {
  if (filters != null) {
    ScheduleSectionRequest.put(filters);
  }

  IntTest.indexScreens = _schedulesIndex;
  IntTest.myTitle = 'График';
  myStream.add(IntTest.indexScreens);
}
