import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../../helper/my_user.dart';
import '../../responsive_screens/responsive.dart';
import '../bloc/work_details_bloc.dart';
import '../models/in_progress_work.dart';
import '../repository/work_details_repository.dart';
import '../widgets/work_card_body.dart';
import '../widgets/work_card_live.dart';
import '../widgets/work_parts.dart';

/// Карточка текущей работы: что там на самом деле происходит.
///
/// Строка раздела отвечает на вопрос «за чем идти» — объект, состояние, кто
/// ведёт. Карточка отвечает на «что там»: чек-лист с отметками, слова механика
/// к пунктам, снимки, времена. Единственное действие в ней — «Позвонить»:
/// работой распоряжается механик в своём телефоне, прораб вмешивается голосом.
///
/// Шапка рисуется из строки, по которой сюда пришли, и появляется сразу — до
/// ответа сервера. Открыв карточку, прораб видит ровно то, на что нажал.
///
/// Виды работ различаются тем, что ниже шапки: у **ТО** — чек-лист и времена,
/// у **заявки** — задание, категория и время заведения. Пустой блок
/// «Чек-лист» заявке не рисуется: его у неё нет вовсе, и место под ним
/// говорило бы, что механик ничего не отметил.
class WorkCardScreen extends StatelessWidget {
  const WorkCardScreen({Key? key, required this.work, this.repository})
      : super(key: key);

  final InProgressWork work;

  /// Подменяется в тестах. В приложении карточка берёт ручки сама — заводить
  /// ради этого провайдер на весь экран сданных работ незачем.
  final WorkDetailsRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkDetailsBloc>(
      create: (_) => WorkDetailsBloc(
        workId: work.workId,
        kind: work.kind,
        repository: repository,
      )..add(const WorkDetailsRequested()),
      child: WorkCardLive(child: _WorkCardView(work: work)),
    );
  }
}

class _WorkCardView extends StatelessWidget {
  const _WorkCardView({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: Column(
        children: <Widget>[
          _Header(size: size),
          Expanded(
            child: BlocBuilder<WorkDetailsBloc, WorkDetailsState>(
              builder: (BuildContext context, WorkDetailsState state) {
                return ListView(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  children: _body(context, state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, WorkDetailsState state) {
    // Работы больше нет — вместо карточки одна плашка с дорогой обратно, и на
    // телефоне, и на широком экране. Ни пилюли состояния, ни звонка: и то и
    // другое говорило бы, что работа идёт прямо сейчас. Карточкой сданной
    // работы этот экран тоже не притворяется — у той свой разговор, с кнопкой
    // «Проверил».
    if (state is WorkGone) {
      return <Widget>[WorkSheet(child: _Gone(work: work, state: state))];
    }

    // На широком экране слева состояние и человек, справа чек-лист во всю
    // высоту; на телефоне то же самое встаёт друг под друга. Порог тот же,
    // что у строки списка, — иначе карточка и список разъедутся.
    final bool narrow = Responsive.isMobile(context);

    final List<Widget> left = <Widget>[
      WorkSheet(child: _Head(work: work)),
      const SizedBox(height: 12.0),
      WorkSheet(
        child: WorkCallBlock(
          state: state,
          fallbackName: work.performerLabel,
          subtitle: work.titleLabel,
        ),
      ),
    ];

    final List<Widget> right = <Widget>[
      if (state is WorkDetailsFailure)
        WorkSheet(child: WorkFailureBlock(message: state.message))
      else if (state is WorkDetailsReady) ...<Widget>[
        WorkSheet(
          child: WorkChecklistBlock(
            checklist: state.details.checklist,
            photos: state.photos,
          ),
        ),
        const SizedBox(height: 12.0),
        WorkSheet(
          child: WorkTimesBlock(
            details: state.details,
            isProblem: work.isProblem,
            loadedAt: state.loadedAt,
            note: 'Работа идёт. Прораб её не правит и не закрывает — это '
                'делает механик в своём телефоне.',
          ),
        ),
      ] else if (state is OrderReady)
        // У заявки один блок вместо двух: времена ей заменяет строка
        // «Заведена», а больше система о ней ничего не записывает.
        WorkSheet(child: WorkOrderBlock(state: state))
      else
        const WorkSheet(child: WorkSkeleton()),
    ];

    if (narrow) {
      return <Widget>[
        ...left,
        const SizedBox(height: 12.0),
        ...right,
      ];
    }

    return <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: left,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: right,
            ),
          ),
        ],
      ),
    ];
  }
}

/// Заголовок экрана — как у ленты сданных работ, но со стрелкой назад вместо
/// бургера: карточка открыта поверх раздела, и уходить из неё некуда, кроме
/// как обратно.
class _Header extends StatelessWidget {
  const _Header({Key? key, required this.size}) : super(key: key);

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
      color: ColorApp.myColorWhite,
      height: 70,
      width: double.infinity,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: size.width > 350 ? 20.0 : 16.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            'Работа',
            style: TextStyle(
              fontSize: size.width > 350 ? 25.0 : 18.0,
              fontWeight: size.width > 350 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(width: size.width > 500 ? 40.0 : 10.0),
          const MyUser(),
        ],
      ),
    );
  }
}

/// Шапка: ровно то, что было в строке, на которую нажали.
///
/// Причина здесь не режется двумя строками — за этим карточку и открывают.
class _Head extends StatelessWidget {
  const _Head({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    final String? reason = work.reasonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: WorkObject(work: work)),
            const SizedBox(width: 8.0),
            WorkBadge(work: work),
          ],
        ),
        const SizedBox(height: 10.0),
        WorkStateLine(work: work),
        if (reason != null) ...<Widget>[
          const SizedBox(height: 10.0),
          WorkReason(text: reason, maxLines: null),
        ],
      ],
    );
  }
}

/// Работы под карточкой больше нет.
///
/// Остаётся только то, что не может устареть: какой это объект и какого вида
/// была работа. Состояние, время и исполнитель ушли вместе с работой — «Идёт ·
/// 41 мин» под закрытым актом было бы ровно тем враньём, ради которого этот
/// экран и заведён.
class _Gone extends StatelessWidget {
  const _Gone({Key? key, required this.work, required this.state})
      : super(key: key);

  final InProgressWork work;
  final WorkGone state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: WorkObject(work: work)),
            const SizedBox(width: 8.0),
            WorkBadge(work: work),
          ],
        ),
        const SizedBox(height: 14.0),
        Text(
          state.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4.0),
        Text(
          state.text,
          style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
        const SizedBox(height: 12.0),
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            // Серая, а не зелёная: это не действие над работой, а выход из
            // экрана, которому больше нечего показать.
            color: ColorApp.myColorGray,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Text(
                  'К списку',
                  style:
                      TextStyle(fontSize: 13.0, color: ColorApp.myColorWhite),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

