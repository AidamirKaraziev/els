import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/my_drawer/my_drawer.dart';
import '../bloc/schedule_divisions_bloc.dart';
import '../bloc/schedules_bloc.dart';
import '../repository/schedules_repository.dart';
import 'schedule_divisions_screen.dart';
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

/// Вход в раздел «Графики».
///
/// Одна развилка по роли на весь раздел: админ начинает с участков, прораб —
/// сразу с ленты объектов своего участка. Из-за неё подмена старых экранов
/// (пункт 1.7 плана) сводится к одной строке в `home_page.dart` и
/// `home_foreman.dart`, а не к разбору ролей в каждом из них.
///
/// Блоки создаются здесь же: снаружи раздел выглядит одним виджетом, и место
/// вызова не должно знать ни про `SchedulesBloc`, ни про репозиторий.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    Key? key,
    required this.role,
    this.repository,
    this.drawer = const MyDrawer(),
  }) : super(key: key);

  final ScheduleRole role;

  /// Боковое меню приложения: у админа своё, у прораба своё. Раздел его не
  /// выбирает — он его получает от того места, куда встроен.
  final Widget drawer;

  /// Откуда брать данные. По умолчанию — фикстура внутри блоков: боевых ручек
  /// у раздела пока нет, это фаза 2.
  final SchedulesRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (role == ScheduleRole.foreman) {
      return BlocProvider<SchedulesBloc>(
        create: (_) => SchedulesBloc(repository: repository),
        child: SchedulesScreen(role: role, drawer: drawer),
      );
    }

    return BlocProvider<ScheduleDivisionsBloc>(
      create: (_) => ScheduleDivisionsBloc(repository: repository),
      child: ScheduleDivisionsScreen(drawer: drawer),
    );
  }
}
