import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../helper/class_colors.dart';
import '../../../in_progress_works/view/employee_card.dart';
import '../../models/month_cell.dart';
import '../../models/schedule_role.dart';
import '../../view/schedule_work_card_screen.dart';
import '../bloc/schedule_object_bloc.dart';
import '../models/schedule_object_card.dart';
import '../models/schedule_responsible.dart';
import '../repository/schedule_object_repository.dart';
import '../widgets/object_info_card.dart';
import '../widgets/object_map_card.dart';
import '../widgets/object_responsibles_card.dart';
import '../widgets/object_schedule_card.dart';
import '../wizard/fixture_schedule_wizard_data.dart';
import '../wizard/view/schedule_wizard_screen.dart';

/// Экран «График объекта».
///
/// Три верхних блока кадра `1182:232` — «Информация об объекте» слева,
/// «Местоположение» и «Ответственные» справа — и блок «Техническое
/// обслуживание» с годовой лентой под ними.
///
/// Из ленты уходят два перехода: клетка ведёт в карточку работы, плашка
/// ответственного — в карточку сотрудника. Оба открываются **маршрутом**
/// поверх экрана, поэтому «назад» возвращает в тот же год ленты: год живёт в
/// блоке, а блок под маршрутом не пересоздаётся.
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
              objectName: objectName,
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
    this.objectName,
  }) : super(key: key);

  final ScheduleObjectLoaded state;
  final ScheduleRole role;
  final double twoColumnsWidth;

  /// Название объекта для шапки карточки работы — то же, что в шапке экрана.
  final String? objectName;

  /// Клик по клетке открывает карточку работы за ней.
  ///
  /// Тем же приёмом, что лента «Графики»: `standalone`, потому что клетка
  /// ведёт в работу любого состояния — назначенную, идущую и закрытую.
  ///
  /// Расхождение с кадром `1182:232`: там работа раскрывается аккордеоном на
  /// месте, под лентой. Здесь — отдельным экраном: карточка работы уже
  /// написана и обкатана, а аккордеон пришлось бы верстать заново ради того
  /// же содержимого. Решено 2 сентября, к кадру вернёмся отдельной задачей.
  void _openWork(BuildContext context, MonthCell cell) {
    if (!cell.isTappable) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ScheduleWorkCardScreen(
          workId: cell.actId!,
          // Своего названия у карточки объекта нет — в ответе `/object/{id}/`
          // его попросту не отдают. Берём то же, что стоит в шапке экрана;
          // пусто — карточка работы напишет «Работа».
          objectName: objectName ?? '',
        ),
      ),
    );
  }

  /// «Создать график на N» открывает мастер расстановки.
  ///
  /// Раньше кнопка слала `ScheduleObjectGenerateRequested` сразу и
  /// раскладывала год одним нажатием. Теперь между нажатием и записью стоят
  /// три шага мастера: программа модели, точка отсчёта, предпросмотр.
  ///
  /// Мастер пока **набросок** и в базу ничего не пишет: он показывает
  /// заготовку на фикстуре и возвращает `true`, если человек её утвердил.
  /// Расстановку по-прежнему делает то же событие — так вид меняется, а
  /// работающее поведение не ломается. Следующей работой мастер сам возьмёт
  /// `preview` и `generate`, и событие уйдёт вместе с фикстурой.
  Future<void> _openWizard(BuildContext context, int year) async {
    final ScheduleObjectBloc bloc = context.read<ScheduleObjectBloc>();
    final bool? approved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ScheduleWizardScreen(
          data: buildWizardFixture(WizardFixture.ok, year: year),
          objectName: objectName,
        ),
      ),
    );
    if (approved != true) return;
    bloc.add(const ScheduleObjectGenerateRequested());
  }

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
        ObjectResponsiblesCard(
          card: card,
          onOpen: (ScheduleResponsible person) =>
              openEmployeeCard(context, person.id!),
        ),
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
          onGenerate: () => _openWizard(context, state.year),
          onCellTap: (MonthCell cell) => _openWork(context, cell),
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
