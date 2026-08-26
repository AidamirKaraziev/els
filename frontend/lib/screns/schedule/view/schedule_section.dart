import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/schedule_divisions_bloc.dart';
import '../bloc/schedules_bloc.dart';
import '../repository/schedules_repository.dart';
import 'schedule_divisions_screen.dart';
import 'schedules_screen.dart';

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
  }) : super(key: key);

  final ScheduleRole role;

  /// Откуда брать данные. По умолчанию — фикстура внутри блоков: боевых ручек
  /// у раздела пока нет, это фаза 2.
  final SchedulesRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (role == ScheduleRole.foreman) {
      return BlocProvider<SchedulesBloc>(
        create: (_) => SchedulesBloc(repository: repository),
        child: SchedulesScreen(role: role),
      );
    }

    return BlocProvider<ScheduleDivisionsBloc>(
      create: (_) => ScheduleDivisionsBloc(repository: repository),
      child: const ScheduleDivisionsScreen(),
    );
  }
}
