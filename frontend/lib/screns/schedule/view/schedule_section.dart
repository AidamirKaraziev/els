import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/my_drawer/my_drawer.dart';
import '../bloc/schedules_bloc.dart';
import '../models/schedule_filters.dart';
import '../repository/schedules_repository.dart';
import 'schedule_object_opener.dart';
import 'schedules_screen.dart';

/// Ширина, с которой оболочка приложения показывает боковое меню сама.
///
/// Порог взят у оболочки (`home_page.dart`, `home_foreman.dart`): там меню
/// становится постоянной колонкой ровно на этой ширине. Своего числа не
/// заводим — разъедутся, и на промежуточной ширине человек останется либо
/// без меню, либо с двумя.
const double kScheduleShellWideWidth = 1350;

/// Показывать ли кнопку слева в шапке раздела.
///
/// Две разные кнопки живут в одном месте: «назад» на вложенном экране и
/// гамбургер на корневом. Назад нужен всегда, гамбургер — только пока меню не
/// стоит колонкой; на широком корневом экране шапка остаётся пустой.
bool scheduleShowsLeading(BuildContext context) =>
    Navigator.of(context).canPop() ||
    MediaQuery.of(context).size.width <= kScheduleShellWideWidth;

/// Заявка «открыть Графики вот с таким отбором».
///
/// Нужна карточке «Выполнение графика» на главной: раздел она не строит —
/// она только переключает оболочку, а с чем открыть ленту, сказать больше
/// негде. Заявка забирается **один раз**: вернувшись в раздел из меню,
/// человек должен увидеть все объекты, а не позавчерашний участок.
///
/// Статикой, а не аргументом: между карточкой и разделом стоит оболочка
/// подрядчика с `IntTest.indexScreens` и списком экранов — передать туда
/// значение по-другому нельзя, не переписав её целиком.
abstract class ScheduleSectionRequest {
  static ScheduleFilters? _pending;

  static void put(ScheduleFilters filters) => _pending = filters;

  /// Отбор заявки, если она есть, и сразу же её гасит.
  static ScheduleFilters? take() {
    final ScheduleFilters? pending = _pending;
    _pending = null;
    return pending;
  }
}

/// Вход в раздел «Графики».
///
/// Обе роли начинают с ленты объектов: у прораба она своего участка, у
/// админа — всех сразу. Разрез по участкам живёт на главной, в карточке
/// «Выполнение графика», и отдельным окном перед лентой не стоит: между
/// человеком и графиками он добавлял клик, а показывал то же самое.
///
/// Блок создаётся здесь же: снаружи раздел выглядит одним виджетом, и место
/// вызова не должно знать ни про `SchedulesBloc`, ни про репозиторий.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    Key? key,
    required this.role,
    this.repository,
    this.initialFilters,
    this.bloc,
    this.opener,
    this.drawer = const MyDrawer(),
  }) : super(key: key);

  final ScheduleRole role;

  /// С каким отбором открыть ленту. Пусто — все объекты за текущий год.
  final ScheduleFilters? initialFilters;

  /// Боковое меню приложения: у админа своё, у прораба своё. Раздел его не
  /// выбирает — он его получает от того места, куда встроен.
  final Widget drawer;

  /// Откуда брать данные. По умолчанию — боевые ручки `/schedules/*`;
  /// подменяется в тестах.
  final SchedulesRepository? repository;

  /// Готовый блок ленты, если им владеет оболочка.
  ///
  /// Оболочка подрядчика держит разделы не стопкой, а одной позицией в
  /// дереве: уходя в «Заявки», человек выносит «Графики» из дерева целиком, и
  /// созданный здесь блок умирает вместе с ними. Возвращаясь, он получал
  /// чистую ленту — год снова текущий, отбор пуст. Поэтому блок живёт у
  /// оболочки (`home_page.dart`, `home_foreman.dart`), а раздел его только
  /// получает; закрывает его тоже она.
  final SchedulesBloc? bloc;

  /// Чем открывать экран «График» по клику в строку. Даёт оболочка: экран
  /// подрядчика показывается сменой её номера экрана, и раздел про это не
  /// знает. Пусто — строка не открывается (так раздел живёт в тестах).
  final ScheduleObjectOpener? opener;

  @override
  Widget build(BuildContext context) {
    final SchedulesBloc? owned = bloc;
    if (owned != null) {
      // `value`, а не `create`: блок чужой, и закрыть его здесь значило бы
      // оставить оболочку с мёртвой лентой на следующем заходе.
      return BlocProvider<SchedulesBloc>.value(
        value: owned,
        child: SchedulesScreen(role: role, drawer: drawer, opener: opener),
      );
    }

    return BlocProvider<SchedulesBloc>(
      create: (_) => SchedulesBloc(
        repository: repository,
        filters: initialFilters,
      ),
      child: SchedulesScreen(role: role, drawer: drawer, opener: opener),
    );
  }
}
