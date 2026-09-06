import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../foreman/defects/defects_repository.dart';
import '../../../foreman/defects/work_defects_section.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/hints/hint_icon.dart';
import '../../../helper/hints/hints.dart';
import '../../in_progress_works/bloc/work_details_bloc.dart';
import '../../submitted_works/models/submitted_work.dart' show WorkKind;
import '../../in_progress_works/repository/work_details_repository.dart';
import '../../in_progress_works/widgets/work_card_body.dart';
import '../widgets/finish_to_button.dart';

class ScheduleWorkCardScreen extends StatelessWidget {
  const ScheduleWorkCardScreen({
    Key? key,
    required this.workId,
    required this.objectName,
    this.repository,
    this.defectsRepository,
    this.onToFinished,
    this.finishRequest,
  }) : super(key: key);

  final int workId;
  final String objectName;
  final WorkDetailsRepository? repository;

  /// Откуда карточка берёт дефекты работы. Подменяется в тестах, как и
  /// [repository]; в бою — живой `DefectsRepository`.
  final DefectsRepository? defectsRepository;

  /// Позвать после закрытия ТО: экрану, откуда пришли, нужно перечитать ленту.
  ///
  /// Зовём сразу по ответу сервера, не дожидаясь возврата назад: карточка
  /// остаётся открытой, а экран под ней успевает обновиться к тому моменту,
  /// когда человек до него дойдёт.
  final VoidCallback? onToFinished;

  /// Подмена запроса закрытия — только для тестов, как и [repository].
  final Future<bool> Function(int actId)? finishRequest;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkDetailsBloc>(
      create: (_) => WorkDetailsBloc(
        workId: workId,
        kind: WorkKind.maintenance,
        // Клетка ведёт в работу любого состояния: назначенную, идущую и
        // закрытую. Фазы списка тут нет — иначе незакрытая работа приезжала
        // бы как «ушла из ленты», а экран показывал бы пустоту.
        phase: WorkPhase.standalone,
        repository: repository,
      )..add(const WorkDetailsRequested()),
      child: _CardView(
        workId: workId,
        objectName: objectName,
        defectsRepository: defectsRepository,
        onToFinished: onToFinished,
        finishRequest: finishRequest,
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({
    Key? key,
    required this.workId,
    required this.objectName,
    this.defectsRepository,
    this.onToFinished,
    this.finishRequest,
  }) : super(key: key);

  final int workId;
  final String objectName;
  final DefectsRepository? defectsRepository;
  final VoidCallback? onToFinished;
  final Future<bool> Function(int actId)? finishRequest;

  @override
  Widget build(BuildContext context) {
    // Один `BlocBuilder` на весь экран, а не только на тело: панель внизу
    // показывает то же состояние работы, что и содержимое, и знать его должна
    // из того же места.
    return BlocBuilder<WorkDetailsBloc, WorkDetailsState>(
      builder: (BuildContext context, WorkDetailsState state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(objectName.isEmpty ? 'Работа' : objectName),
            // Значок в шапке, а не у блока времён: `WorkTimesBlock` общий с
            // карточками идущих и сданных работ, и подсказка про закрытие ТО
            // уехала бы туда, где ТО ни при чём.
            actions: const <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Center(
                    child: HintIcon(id: HintIds.scheduleFinishTo, size: 20.0)),
              ),
            ],
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: ColorApp.myColorBlack,
          ),
          body: _body(state),
          bottomNavigationBar: _finishBar(context, state),
        );
      },
    );
  }

  Widget _body(WorkDetailsState state) {
    if (state is WorkDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is WorkDetailsFailure) {
      return Center(
        child: Text(state.message),
      );
    }

    if (state is WorkDetailsReady) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkChecklistBlock(
              checklist: state.details.checklist,
              photos: state.photos,
            ),
            const SizedBox(height: 16),
            // Между чек-листом и временами: дефект — это то, что механик
            // нашёл, проходя чек-лист, и читается он следом за ним.
            WorkDefectsSection(
              workId: workId,
              objectName: objectName,
              repository: defectsRepository,
            ),
            const SizedBox(height: 16),
            WorkTimesBlock(
              details: state.details,
              isProblem: false,
              showFinished: true,
              // У назначенной работы времён нет ни одного, и блок
              // «Времена» остался бы пустым заголовком. Сноска говорит,
              // почему он пуст: работу ещё не делали.
              note: state.details.isFinished
                  ? 'Информация о выполнении работы'
                  : state.details.startedAt == null
                      ? 'Работа ещё не начата'
                      : 'Работа идёт',
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Закрепить закрытие ТО внизу экрана.
  ///
  /// Чек-лист ТО длинный — у иных видов работ за сотню пунктов, — и
  /// единственное действие карточки не должно уезжать под прокрутку. Пока
  /// работа не загрузилась, низа нет: закрывать нечего и дату показать нечем.
  Widget? _finishBar(BuildContext context, WorkDetailsState state) {
    if (state is! WorkDetailsReady) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: FinishTOButton(
            actId: workId,
            finishedAt: state.details.finishedAt,
            request: finishRequest,
            onFinished: () async {
              // Карточку перечитываем молча: кнопка на месте сменяется
              // строкой «ТО завершено», человек остаётся на том же экране.
              context.read<WorkDetailsBloc>().add(const WorkDetailsRefreshed());
              onToFinished?.call();
            },
          ),
        ),
      ),
    );
  }
}
