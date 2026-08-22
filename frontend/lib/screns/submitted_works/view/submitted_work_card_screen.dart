import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../../helper/my_user.dart';
import '../../in_progress_works/bloc/work_details_bloc.dart';
import '../../in_progress_works/repository/work_details_repository.dart';
import '../../in_progress_works/widgets/work_card_body.dart';
import '../../responsive_screens/responsive.dart';
import '../models/submitted_work.dart';
import '../widgets/submitted_work_parts.dart';

/// Карточка сданной работы: что именно прораб отмечает проверенным.
///
/// Строка ленты отвечает на «что и где сдали». Карточка отвечает на «как
/// сдали»: чек-лист с отметками, слова механика к пунктам, снимки, времена — у
/// ТО; задание, категория и причина неисправности — у заявки. Пока этого не
/// видно, «Проверил» — отметка о том, что прораб посмотрел на строку списка.
///
/// Тело у неё то же самое, что у карточки текущей работы
/// (`in_progress_works/widgets/work_card_body.dart`): один и тот же чек-лист до
/// сдачи и после, и разным он быть не может. Разное — края. Там работа идёт и
/// карточка перечитывает себя раз в минуту; здесь работа кончилась, читать
/// заново нечего, а край — обратный: если работу открыли заново, из ленты
/// сданных она ушла.
class SubmittedWorkCardScreen extends StatefulWidget {
  const SubmittedWorkCardScreen({
    Key? key,
    required this.work,
    this.onReview,
    this.repository,
  }) : super(key: key);

  /// Строка, по которой сюда пришли. Из неё рисуется шапка — сразу, до ответа
  /// сервера: открыв карточку, прораб видит ровно то, на что нажал.
  final SubmittedWork work;

  /// Отметить работу проверенной. Ходит в ленту, а не в сервер напрямую:
  /// отметка из карточки и отметка кнопкой в строке должны быть одним и тем же
  /// действием — иначе счётчик в меню и лента разойдутся.
  ///
  /// `null` — отмечать некому (карточку открыли не из ленты).
  final VoidCallback? onReview;

  /// Подменяется в тестах. В приложении карточка берёт ручки сама.
  final WorkDetailsRepository? repository;

  @override
  State<SubmittedWorkCardScreen> createState() =>
      _SubmittedWorkCardScreenState();
}

class _SubmittedWorkCardScreenState extends State<SubmittedWorkCardScreen> {
  late SubmittedWork _work = widget.work;

  /// Отметку показываем сразу, не дожидаясь ленты: имени проверившего у
  /// клиента нет — его подставит сервер, и в списке прораб увидит настоящее
  /// «кто и когда», когда вернётся. Врать в карточке нечем: «Проверено» без
  /// имени — правда.
  void _review() {
    widget.onReview?.call();
    setState(() => _work = _work.markedReviewed(by: null));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkDetailsBloc>(
      create: (_) => WorkDetailsBloc(
        workId: _work.workId,
        kind: _work.kind,
        phase: WorkPhase.submitted,
        repository: widget.repository,
      )..add(const WorkDetailsRequested()),
      child: _CardView(
        work: _work,
        onReview: widget.onReview == null ? null : _review,
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({Key? key, required this.work, this.onReview})
      : super(key: key);

  final SubmittedWork work;
  final VoidCallback? onReview;

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
    // Работу вернули в работу, пока карточка была открыта. Ни чек-листа, ни
    // отметки «Проверил»: проверять нечего, работа не сдана.
    if (state is WorkGone) {
      return <Widget>[WorkSheet(child: _Gone(work: work, state: state))];
    }

    // Порог тот же, что у строки ленты и у карточки текущей работы, — иначе
    // экраны разъедутся.
    final bool narrow = Responsive.isMobile(context);

    final List<Widget> left = <Widget>[
      WorkSheet(child: _Head(work: work)),
      const SizedBox(height: 12.0),
      WorkSheet(child: _Review(work: work, onReview: onReview)),
      const SizedBox(height: 12.0),
      WorkSheet(
        child: WorkCallBlock(state: state, fallbackName: work.performerLabel),
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
            showFinished: true,
            // «Обновлено» здесь не нужно: сданная работа не меняется, и
            // карточка не перечитывает себя. Строка про свежесть отвечала бы
            // на вопрос, которого никто не задаёт.
            note: 'Работа закрыта механиком. Прораб её не правит — карточка '
                'показывает, что было сделано.',
          ),
        ),
      ] else if (state is OrderReady)
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

/// Заголовок экрана — как у карточки текущей работы, со стрелкой назад:
/// карточка открыта поверх ленты, и уходить из неё некуда, кроме как обратно.
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
          // Заголовок гибкий: «Сданная работа» длиннее «Работы» из карточки
          // текущей, и на узком экране рядом с аватаром он не помещается.
          Flexible(
            child: Text(
              'Сданная работа',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size.width > 350 ? 25.0 : 18.0,
                fontWeight:
                    size.width > 350 ? FontWeight.w700 : FontWeight.w500,
              ),
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

/// Шапка: ровно то, что было в строке ленты, на которую нажали.
class _Head extends StatelessWidget {
  const _Head({Key? key, required this.work}) : super(key: key);

  final SubmittedWork work;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: SubmittedWorkObject(work: work)),
            const SizedBox(width: 8.0),
            SubmittedWorkBadges(work: work),
          ],
        ),
        const SizedBox(height: 12.0),
        WorkFact(name: 'Сдал', value: work.performerLabel),
        WorkFact(name: 'Сдана', value: work.closedLabel),
      ],
    );
  }
}

/// Отметка «Проверил» — второе действие карточки после звонка.
///
/// Стоит выше чек-листа на телефоне и слева от него на широком экране: прораб
/// сначала читает, что сделано, и отмечает уже осознанно. Отмеченную работу
/// подписываем именем и временем, а кнопку убираем: отмечать дважды нечего.
class _Review extends StatelessWidget {
  const _Review({Key? key, required this.work, required this.onReview})
      : super(key: key);

  final SubmittedWork work;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    if (work.isReviewed) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline,
            size: 18.0,
            color: ColorApp.myColorGreenAuth,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              work.reviewedLabel ?? 'Проверено',
              style: const TextStyle(fontSize: 13.0),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Работу ещё не смотрели.',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
        const SizedBox(height: 10.0),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: onReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorApp.myColorGreenAuth,
              foregroundColor: ColorApp.myColorWhite,
              elevation: 0.0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Проверил'),
          ),
        ),
      ],
    );
  }
}

/// Работы в ленте сданных больше нет — её открыли заново.
///
/// Остаётся только то, что не может устареть: объект и вид работы. Чек-лист
/// закрытой работы под заново открытой врал бы ровно так же, как пилюля «Идёт»
/// под закрытым актом в карточке текущей работы.
class _Gone extends StatelessWidget {
  const _Gone({Key? key, required this.work, required this.state})
      : super(key: key);

  final SubmittedWork work;
  final WorkGone state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: SubmittedWorkObject(work: work)),
            const SizedBox(width: 8.0),
            SubmittedWorkBadges(work: work),
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
