import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../helper/class_colors.dart';
import '../../models/month_cell.dart';
import '../../models/schedule_role.dart';
import '../bloc/schedule_object_bloc.dart';
import '../models/schedule_object_card.dart';
import '../repository/schedule_object_repository.dart';
import '../widgets/object_info_card.dart';
import '../widgets/object_map_card.dart';
import '../widgets/object_responsibles_card.dart';
import '../widgets/object_schedule_card.dart';

/// Экран «График объекта».
///
/// Три верхних блока кадра `1182:232` — «Информация об объекте» слева,
/// «Местоположение» и «Ответственные» справа — и блок «Техническое
/// обслуживание» с годовой лентой под ними. Список работ под лентой — `S2.3`;
/// места под него здесь ещё нет намеренно, чтобы пустая заглушка не выглядела
/// сломанным экраном.
///
/// Экран заводится **рядом** со старым `SchedulePage` подрядчика, а не вместо
/// него: тот в проде, на нём висят все действия с ТО, и переключать на новый
/// нечего, пока новый не показывает график.
class ScheduleObjectScreen extends StatelessWidget {
  const ScheduleObjectScreen({
    Key? key,
    required this.objectId,
    required this.repository,
    this.role = ScheduleRole.admin,
    this.objectName,
    this.initialYear,
  }) : super(key: key);

  final int objectId;

  /// Откуда берутся карточка и лента. Обязателен: под ним стоит либо
  /// фикстура, либо сеть, и умолчания у него быть не должно.
  final ScheduleObjectRepository repository;

  /// Чьими глазами открыт экран. Три верхних блока у ролей одинаковые; роль
  /// решает, показывать ли кнопку создания графика.
  final ScheduleRole role;

  /// Название объекта для шапки, если место вызова его знает. Лента знает —
  /// и тогда человек видит, чей график открыл, ещё до загрузки карточки.
  final String? objectName;

  /// Год, с которого открывается лента. По умолчанию текущий — решение 8.
  final int? initialYear;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleObjectBloc>(
      create: (_) => ScheduleObjectBloc(
        repository: repository,
        objectId: objectId,
        initialYear: initialYear,
      )..add(const ScheduleObjectRequested()),
      child: _ScheduleObjectView(objectName: objectName, role: role),
    );
  }
}

class _ScheduleObjectView extends StatelessWidget {
  const _ScheduleObjectView({
    Key? key,
    this.objectName,
    required this.role,
  }) : super(key: key);

  /// Ширина, ниже которой две колонки кадра встают одна под другой.
  ///
  /// Кадр нарисован на широком экране; на планшете и телефоне карточка
  /// «Информация» с картой рядом ужимается до нечитаемой.
  static const double _twoColumnsWidth = 1000.0;

  final String? objectName;
  final ScheduleRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: Text(
          objectName ?? 'График',
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: ColorApp.myColorBlack,
          ),
        ),
      ),
      body: BlocBuilder<ScheduleObjectBloc, ScheduleObjectState>(
        builder: (BuildContext context, ScheduleObjectState state) {
          if (state is ScheduleObjectFailure) {
            return _Failure(message: state.message);
          }
          if (state is ScheduleObjectLoaded) {
            return _Content(
              state: state,
              role: role,
              twoColumnsWidth: _twoColumnsWidth,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    Key? key,
    required this.state,
    required this.role,
    required this.twoColumnsWidth,
  }) : super(key: key);

  final ScheduleObjectLoaded state;
  final ScheduleRole role;
  final double twoColumnsWidth;

  @override
  Widget build(BuildContext context) {
    final ScheduleObjectCard card = state.card;
    final bool wide = MediaQuery.of(context).size.width >= twoColumnsWidth;
    final Widget info = ObjectInfoCard(card: card);
    final Widget right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ObjectMapCard(geo: card.geo),
        const SizedBox(height: 24.0),
        ObjectResponsiblesCard(card: card),
        const SizedBox(height: 24.0),
        ObjectScheduleCard(
          year: state.year,
          cells: state.cells,
          role: role,
          isLoading: state.isYearLoading,
          isGenerating: state.isGenerating,
          error: state.yearError,
          onYearChanged: (int year) => context
              .read<ScheduleObjectBloc>()
              .add(ScheduleObjectYearRequested(year)),
          onGenerate: () => context
              .read<ScheduleObjectBloc>()
              .add(const ScheduleObjectGenerateRequested()),
          // Клик по клетке открывает карточку работы — это `S2.3`. Пока
          // клетка молчит: заглушка, которая «нажимается» и ничего не
          // делает, хуже клетки, которая честно не нажимается.
          onCellTap: (MonthCell cell) {},
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ColorApp.kPadding),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Пропорция колонок с кадра: узкая карточка полей и широкая
                // правая часть с картой, ответственными и лентой месяцев.
                Expanded(flex: 4, child: info),
                const SizedBox(width: 24.0),
                Expanded(flex: 7, child: right),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                info,
                const SizedBox(height: 24.0),
                right,
              ],
            ),
    );
  }
}

/// Карточку загрузить не удалось: текст и повтор.
class _Failure extends StatelessWidget {
  const _Failure({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColorApp.myColorGray),
          ),
          const SizedBox(height: 12.0),
          TextButton(
            onPressed: () => context
                .read<ScheduleObjectBloc>()
                .add(const ScheduleObjectRequested()),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
