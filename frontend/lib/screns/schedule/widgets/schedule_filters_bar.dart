import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/schedule_filters.dart';
import '../repository/schedules_repository.dart';
import 'schedule_search_field.dart';
import 'schedule_year_picker.dart';

/// Панель над лентой графиков: год, пять фильтров и поиск.
///
/// Раскладка по кадру Figma `83:312` — белая карточка, внутри пилюли высотой
/// [_pillHeight] с кеглем 10 и треугольником-стрелкой справа.
///
/// Пилюли лежат во `Wrap`, а не в `Row`: пять фильтров рядом с годом и лупой не
/// помещаются уже на 960, а `Row` обрезал бы последние молча — ровно так на
/// старом экране пропадали «Тип» и «Графики», спрятанные за `if (size.width >
/// 1150)`.
///
/// Фильтр применяется **сразу при выборе**: кнопки «Применить» в макете нет, и
/// заводить её значило бы добавить шаг, о котором человеку никто не сказал.
class ScheduleFiltersBar extends StatelessWidget {
  const ScheduleFiltersBar({
    Key? key,
    required this.filters,
    required this.options,
    required this.onChanged,
  }) : super(key: key);

  final ScheduleFilters filters;
  final ScheduleFilterOptions options;

  /// Наверх уходит готовый отбор целиком: экран не собирает его по кусочкам и
  /// не помнит, какое поле только что тронули.
  final ValueChanged<ScheduleFilters> onChanged;

  static const double _pillHeight = 24.0;
  static const double _fontSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ScheduleYearPicker(
            year: filters.year,
            onChanged: (int year) => onChanged(filters.copyWith(year: year)),
          ),
          _FilterPill(
            hint: 'Название',
            items: options.names,
            value: filters.name,
            onChanged: (FilterOption? option) => onChanged(
              filters.copyWith(name: option, clearName: option == null),
            ),
          ),
          _FilterPill(
            hint: 'Заводской номер',
            items: options.factoryNumbers,
            value: filters.factoryNumber,
            onChanged: (FilterOption? option) => onChanged(
              filters.copyWith(
                factoryNumber: option,
                clearFactoryNumber: option == null,
              ),
            ),
          ),
          _FilterPill(
            hint: 'Участок',
            // «Без участка» стоит первым и приходит не с сервера: это не
            // участок из справочника, а объекты, которым его не проставили.
            items: <FilterOption>[kWithoutDivision, ...options.divisions],
            value: filters.division,
            onChanged: (FilterOption? option) => onChanged(
              filters.copyWith(division: option, clearDivision: option == null),
            ),
          ),
          _FilterPill(
            hint: 'Тип',
            items: options.types,
            value: filters.typeObject,
            onChanged: (FilterOption? option) => onChanged(
              filters.copyWith(
                typeObject: option,
                clearTypeObject: option == null,
              ),
            ),
          ),
          // «Графики» — состояние ТО за год, а не справочник: значения известны
          // в коде и с сервера не приходят.
          _StatePill(
            value: filters.state,
            onChanged: (ScheduleState? state) => onChanged(
              filters.copyWith(state: state, clearState: state == null),
            ),
          ),
          ScheduleSearchField(
            text: filters.search,
            onSearch: (String text) => onChanged(filters.copyWith(search: text)),
          ),
          // Сбрасывать всё есть смысл, только когда условий больше одного: при
          // единственном фильтре его собственный крестик и есть эта кнопка.
          if (filters.activeCount > 1)
            _ResetAllButton(
              count: filters.activeCount,
              onPressed: () => onChanged(filters.cleared()),
            ),
        ],
      ),
    );
  }
}

/// Пилюля выпадающего фильтра со значениями из справочника.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    Key? key,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String hint;
  final List<FilterOption> items;
  final FilterOption? value;
  final ValueChanged<FilterOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Значение, которого нет в списке, роняет `DropdownButton`. Так бывает,
    // когда справочник приехал позже выбора или ужался под права человека.
    //
    // Берём **пункт из списка**, а не пришедшее значение: `DropdownButton`
    // сверяет их целиком, и участок с тем же id, но другим названием — так
    // приходит выбор с главной — роняет экран той же ошибкой.
    FilterOption? known;
    for (final FilterOption item in items) {
      if (item.id == value?.id) {
        known = item;
        break;
      }
    }

    return _PillShell(
      active: known != null,
      onReset: known == null ? null : () => onChanged(null),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FilterOption?>(
          value: known,
          isDense: true,
          borderRadius: BorderRadius.circular(6),
          hint: _PillLabel(text: hint, active: false),
          // Выбранное значение в пилюле рисуется своей надписью, а не пунктом
          // меню: пункт кеглем 12 и высотой 48 в пилюлю на 24 не помещается.
          selectedItemBuilder: (BuildContext context) => <Widget>[
            for (final FilterOption item in items)
              _PillLabel(text: item.title, active: true),
          ],
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: ColorApp.myColorGreenAuth,
          ),
          items: <DropdownMenuItem<FilterOption?>>[
            for (final FilterOption item in items)
              DropdownMenuItem<FilterOption?>(
                value: item,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: ScheduleFiltersBar._fontSize + 2,
                    color: ColorApp.myColorBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

/// Пилюля «Графики» — состояние ТО объекта за выбранный год.
class _StatePill extends StatelessWidget {
  const _StatePill({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final ScheduleState? value;
  final ValueChanged<ScheduleState?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PillShell(
      active: value != null,
      onReset: value == null ? null : () => onChanged(null),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ScheduleState?>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(6),
          hint: const _PillLabel(text: 'Графики', active: false),
          selectedItemBuilder: (BuildContext context) => <Widget>[
            for (final ScheduleState state in ScheduleState.values)
              _PillLabel(text: state.title, active: true),
          ],
          icon: const Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: ColorApp.myColorGreenAuth,
          ),
          items: <DropdownMenuItem<ScheduleState?>>[
            for (final ScheduleState state in ScheduleState.values)
              DropdownMenuItem<ScheduleState?>(
                value: state,
                child: Text(
                  state.title,
                  style: const TextStyle(
                    fontSize: ScheduleFiltersBar._fontSize + 2,
                    color: ColorApp.myColorBlack,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Оболочка пилюли: рамка, заливка и крестик сброса.
///
/// Крестик стоит **снаружи** выпадающего списка. Пункт «все» внутри списка —
/// то же действие, но за двумя нажатиями и без единого места, где видно, что
/// фильтр вообще стоит.
class _PillShell extends StatelessWidget {
  const _PillShell({
    Key? key,
    required this.active,
    required this.onReset,
    required this.child,
  }) : super(key: key);

  final bool active;
  final VoidCallback? onReset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScheduleFiltersBar._pillHeight,
      padding: EdgeInsets.only(left: 8, right: active ? 2 : 4),
      decoration: BoxDecoration(
        color: active ? ColorApp.myColorGreenLine : ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: ColorApp.myColorGreenAuth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          child,
          if (onReset != null)
            Tooltip(
              message: 'Сбросить фильтр',
              child: InkWell(
                onTap: onReset,
                child: const SizedBox(
                  width: 18,
                  height: ScheduleFiltersBar._pillHeight,
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: ColorApp.myColorGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Надпись внутри пилюли: заголовок фильтра либо выбранное значение.
class _PillLabel extends StatelessWidget {
  const _PillLabel({Key? key, required this.text, required this.active})
      : super(key: key);

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // Длинное название объекта иначе растянуло бы пилюлю на пол-экрана и
      // вытолкнуло остальные фильтры на вторую строку.
      constraints: const BoxConstraints(maxWidth: 140),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ScheduleFiltersBar._fontSize,
          fontWeight: active ? FontWeight.w500 : FontWeight.w400,
          color: ColorApp.myColorBlack,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ResetAllButton extends StatelessWidget {
  const _ResetAllButton({
    Key? key,
    required this.count,
    required this.onPressed,
  }) : super(key: key);

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: ScheduleFiltersBar._pillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        // `Row` с `MainAxisSize.min`, а не `alignment: center`: `Wrap` даёт
        // детям ограниченную ширину, и центрирующий `Container` занимал всю
        // строку — надпись уезжала на середину панели, будто её там и ждали.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Сбросить всё ($count)',
              style: const TextStyle(
                fontSize: ScheduleFiltersBar._fontSize,
                fontWeight: FontWeight.w500,
                color: ColorApp.myColorGreenAuth,
                decoration: TextDecoration.underline,
                decorationColor: ColorApp.myColorGreenAuth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
