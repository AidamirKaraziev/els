/// Тело карточки работы: чек-лист со снимками, времена, блок заявки, звонок.
///
/// Лежат отдельным файлом по той же причине, что и части строки в
/// `work_parts.dart`: этими блоками собраны **две** карточки — текущей работы у
/// прораба и сданной в ленте проверки, — и разойтись они не должны. Прораб
/// смотрит на один и тот же чек-лист до сдачи и после; увидеть его по-разному
/// он не может.
///
/// Что зависит от конкретной работы — шапка, пилюля состояния, дорога назад, —
/// осталось в экранах: у идущей работы и у сданной они разные.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../helper/api_image.dart';
import '../../../helper/class_colors.dart';
import '../bloc/work_details_bloc.dart';
import '../models/order_details.dart';
import '../models/work_details.dart';
import '../state_colors.dart';
import '../view/employee_card.dart';

/// Белый блок карточки. Их в ней три: шапка со звонком, чек-лист, времена.
class WorkSheet extends StatelessWidget {
  const WorkSheet({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      margin: const EdgeInsets.only(bottom: 2.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: child,
    );
  }
}

/// Кому звонить.
///
/// Работу ведёт механик, а прораб вмешивается голосом — и до сдачи, и после
/// неё: у сданной работы вопросы к чек-листу задают тому же человеку.
class WorkCallBlock extends StatelessWidget {
  const WorkCallBlock({
    Key? key,
    required this.state,
    required this.fallbackName,
    this.subtitle,
  }) : super(key: key);

  final WorkDetailsState state;

  /// Имя из строки, по которой открыли карточку. Показывается, пока едет
  /// справочник, и остаётся, если он не ответил.
  final String fallbackName;

  /// Чем подписать человека помимо специальности: у текущей работы это
  /// регламент из строки, у сданной подписывать нечем.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // Через общего предка: у ТО телефон приезжает из справочника, у заявки —
    // вместе с ней самой, а разговор с прорабом про звонок один и тот же.
    final WorkCardReady? ready =
        state is WorkCardReady ? state as WorkCardReady : null;
    final Performer? performer = ready?.performer;

    // Имя показываем то, что пришло со строкой: справочник может отвечать
    // дольше, а звать механика по имени прораб должен сразу.
    final String name = performer?.name ?? fallbackName;
    final String? meta = _meta(performer);

    final Widget who = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(name, style: const TextStyle(fontSize: 13.0)),
        if (meta != null)
          Text(
            meta,
            style: const TextStyle(
              fontSize: 11.0,
              color: ColorApp.myColorGray,
            ),
          ),
      ],
    );

    if (performer != null && performer.hasPhone) {
      return _CallReady(performer: performer, who: who);
    }

    // Справочник не ответил — это не то же самое, что пустое поле: там чинить
    // нечего, здесь чинить некому. Слова разные.
    if (ready != null && ready.performerFailed) {
      return _CallShell(
        who: who,
        trailing: const Text(
          'Телефон не загрузился',
          style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      );
    }

    // Подробности ещё едут: молчим о телефоне, пока не знаем, есть ли он.
    if (ready == null) {
      return _CallShell(who: who, trailing: const SizedBox.shrink());
    }

    return _CallMissing(performer: performer, who: who);
  }

  /// «Механик · ТО-2»: специальность из справочника и подпись из строки.
  String? _meta(Performer? performer) {
    final List<String> parts = <String>[
      if (performer?.specialty != null) performer!.specialty!,
      if (subtitle != null) subtitle!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Серая плашка со звонком: слева человек, справа действие.
class _CallShell extends StatelessWidget {
  const _CallShell({Key? key, required this.who, required this.trailing})
      : super(key: key);

  final Widget who;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: who),
          const SizedBox(width: 10.0),
          trailing,
        ],
      ),
    );
  }
}

/// Номер есть: зелёная кнопка справа.
class _CallReady extends StatelessWidget {
  const _CallReady({Key? key, required this.performer, required this.who})
      : super(key: key);

  final Performer performer;
  final Widget who;

  @override
  Widget build(BuildContext context) {
    return _CallShell(
      who: who,
      trailing: Material(
        color: ColorApp.myColorGreenAuth,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () => _call(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
            child: Text(
              'Позвонить',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorWhite),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    final Uri uri = Uri(scheme: 'tel', path: performer.callUri);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!context.mounted) return;
      // На вебе без телефонии звонок никуда не уйдёт — тогда хотя бы покажем
      // номер, чтобы его можно было набрать руками.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Позвонить не вышло. Номер: '
            '${performer.phoneLabel ?? performer.callUri}')),
      );
    }
  }
}

/// Номера нет. Кнопки нет тоже — неработающая кнопка хуже её отсутствия, — но
/// на её месте сказано, чего именно не хватает и что с этим делать.
///
/// Жёлтый, а не красный: красный в этом разделе занят незакрытой проблемой в
/// работе, и пустое поле справочника не должно кричать наравне с ней.
class _CallMissing extends StatelessWidget {
  const _CallMissing({Key? key, required this.performer, required this.who})
      : super(key: key);

  final Performer? performer;
  final Widget who;

  @override
  Widget build(BuildContext context) {
    final int? userId = performer?.id;
    final bool canFix = userId != null && userId > 0 && canOpenEmployeeCard;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xffC6CBC6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                who,
                if (canFix) ...<Widget>[
                  const SizedBox(height: 4.0),
                  InkWell(
                    // Ждём, пока человек вернётся, и перечитываем телефон: за
                    // ним он туда и ходил, а увидеть на прежнем месте «Номер
                    // не указан» после того, как номер вписан, — читается как
                    // несохранившаяся правка.
                    onTap: () async {
                      await openEmployeeCard(context, userId);
                      if (!context.mounted) return;
                      context
                          .read<WorkDetailsBloc>()
                          .add(const WorkPerformerRequested());
                    },
                    child: const Text(
                      'Добавить номер',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: runningText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 14.0,
                height: 14.0,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: pauseBackground,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: pauseText,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              const Text(
                'Номер не указан',
                style: TextStyle(fontSize: 12.0, color: pauseText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Чек-лист: что механик прошёл и что сказал по дороге.
class WorkChecklistBlock extends StatefulWidget {
  const WorkChecklistBlock({Key? key, required this.checklist, required this.photos})
      : super(key: key);

  final WorkChecklist checklist;
  final WorkPhotos photos;

  /// Механик прошёл чек-лист молча: ни одного комментария, ни одного снимка.
  ///
  /// Считаем по всем пунктам, а не по видимым: иначе подпись пропадала бы от
  /// нажатия «и ещё N», хотя ничего не изменилось.
  bool get wordless => checklist.steps.every(
        (ChecklistStep step) =>
            step.comment == null && photos.of(step).isEmpty,
      );

  @override
  State<WorkChecklistBlock> createState() => _WorkChecklistBlockState();
}

class _WorkChecklistBlockState extends State<WorkChecklistBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final WorkChecklist checklist = widget.checklist;

    if (checklist.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          WorkBlockTitle(text: 'Чек-лист'),
          SizedBox(height: 10.0),
          // Пустой чек-лист — это «регламент не заполнен», а не «ничего не
          // сделано». Ноль пунктов сказал бы второе.
          Text(
            'Чек-лист не заполнен',
            style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
          ),
        ],
      );
    }

    final List<ChecklistStep> steps = checklist.visible(expanded: _expanded);
    final int hidden = checklist.hiddenCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WorkBlockTitle(text: 'Чек-лист · ${checklist.progressLabel}'),
        const SizedBox(height: 4.0),
        for (int i = 0; i < steps.length; i++)
          _Step(
            step: steps[i],
            photos: widget.photos.of(steps[i]),
            last: i == steps.length - 1 && (hidden == 0 || _expanded),
          ),
        if (hidden > 0 && !_expanded)
          InkWell(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9.0),
              child: Text(
                checklist.hiddenLabel,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ),
          ),
        // Молчание механика подписано словами. Пустое место под пунктами
        // прораб читает как потерянные фотографии — а их и не было.
        if (widget.wordless) ...<Widget>[
          const SizedBox(height: 8.0),
          const Text(
            'Снимков и комментариев механик не оставил.',
            style: TextStyle(fontSize: 11.0, color: ColorApp.myColorGrayText),
          ),
        ],
      ],
    );
  }
}

/// Пункт регламента: отметка, название, слова механика и его снимки — всё
/// внутри своего пункта. «Износ выше нормы» без названия шага ничего не значит.
class _Step extends StatelessWidget {
  const _Step({
    Key? key,
    required this.step,
    required this.photos,
    required this.last,
  }) : super(key: key);

  final ChecklistStep step;
  final List<String> photos;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final String? comment = step.comment;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9.0),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: ColorApp.myColorGrayBorder),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Box(done: step.done),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(step.title, style: const TextStyle(fontSize: 13.0)),
                if (comment != null) ...<Widget>[
                  const SizedBox(height: 3.0),
                  Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: ColorApp.myColorGray,
                    ),
                  ),
                ],
                if (photos.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: photos
                        .map((String photo) => _Thumb(photo: photo))
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Квадратная отметка пункта.
class _Box extends StatelessWidget {
  const _Box({Key? key, required this.done}) : super(key: key);

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16.0,
      height: 16.0,
      margin: const EdgeInsets.only(top: 2.0),
      decoration: BoxDecoration(
        color: done ? ColorApp.myColorGreenAuth : ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: done ? ColorApp.myColorGreenAuth : const Color(0xffC6CBC6),
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 12.0, color: ColorApp.myColorWhite)
          : null,
    );
  }
}

/// Миниатюра снимка. Полноразмер — по нажатию.
///
/// Грузится через [apiImageWidget]: `/api/v1/static/…` требует токена, и
/// заголовок к картинке подставляет он.
class _Thumb extends StatelessWidget {
  const _Thumb({Key? key, required this.photo}) : super(key: key);

  final String photo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (BuildContext context) => Dialog(
          insetPadding: const EdgeInsets.all(24.0),
          child: InteractiveViewer(
            child: apiImageWidget(photo, fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          width: 44.0,
          height: 44.0,
          color: ColorApp.myColorGrayBorder,
          child: apiImageWidget(photo, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Времена работы.
///
/// «Обновлено» тикает раз в минуту: карточку идущей работы держат открытой,
/// читая чек-лист, и застывшее «только что» врало бы ровно тогда, когда прораб
/// решает, перечитать или звонить. У сданной работы этой строки нет вовсе:
/// перечитывать нечего, работа кончилась, и «Обновлено» отвечало бы на вопрос,
/// которого никто не задаёт.
class WorkTimesBlock extends StatefulWidget {
  const WorkTimesBlock({
    Key? key,
    required this.details,
    required this.isProblem,
    this.loadedAt,
    this.showFinished = false,
    this.note,
  }) : super(key: key);

  final WorkDetails details;

  /// Работа кончилась проблемой. Строка про это стоит и в сданной карточке:
  /// момента, когда механик объявил проблему, система не хранит.
  final bool isProblem;

  /// Когда карточка забрала данные. `null` — живого «Обновлено» нет и минутный
  /// такт не заводится.
  final DateTime? loadedAt;

  /// Показывать ли «Закончил». У идущей работы этого времени ещё нет.
  final bool showFinished;

  /// Сноска под временами. У каждой карточки своя, и общей быть не может.
  final String? note;

  @override
  State<WorkTimesBlock> createState() => _WorkTimesBlockState();
}

class _WorkTimesBlockState extends State<WorkTimesBlock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (widget.loadedAt == null) return;
    _tick = Timer.periodic(
      const Duration(minutes: 1),
      (Timer _) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkDetails details = widget.details;
    final String? started = stampLabel(details.startedAt);
    final String? paused = stampLabel(details.pausedAt);
    final String? finished =
        widget.showFinished ? stampLabel(details.finishedAt) : null;
    final DateTime? loadedAt = widget.loadedAt;
    final String? note = widget.note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WorkBlockTitle(text: 'Времена'),
        const SizedBox(height: 10.0),
        if (started != null) WorkFact(name: 'Начал работу', value: started),
        if (paused != null) WorkFact(name: 'Встал', value: paused),
        // Момент, когда механик объявил проблему, в базе не хранится — и
        // выдумывать его карточка не будет. Прораб видит, что это ограничение
        // системы, а не пробел в работе механика.
        if (widget.isProblem)
          const WorkFact(
            name: 'Объявил проблему',
            value: 'не записано',
            faint: true,
          ),
        if (finished != null) WorkFact(name: 'Закончил', value: finished),
        if (loadedAt != null)
          WorkFact(name: 'Обновлено', value: agoLabel(loadedAt)),
        if (note != null) ...<Widget>[
          const SizedBox(height: 8.0),
          Text(
            note,
            style: const TextStyle(
              fontSize: 11.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
        ],
      ],
    );
  }
}

/// Заявка: что просили сделать, чем это назвали и когда завели.
///
/// Чек-листа у заявки нет, и выдумывать ему замену карточка не станет:
/// задание — это слова диспетчера, а не регламент. Снимки лежат общим рядом
/// внизу, а не по пунктам: пунктов, к которым их можно было бы привязать, у
/// заявки не бывает.
class WorkOrderBlock extends StatelessWidget {
  const WorkOrderBlock({Key? key, required this.state}) : super(key: key);

  final OrderReady state;

  @override
  Widget build(BuildContext context) {
    final OrderDetails order = state.order;
    final String? task = order.taskLabel;
    final String? reason = order.reasonLabel;
    final String? created = order.createdLabel;
    final List<String> photos = state.photos.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const WorkBlockTitle(text: 'Заявка'),
        const SizedBox(height: 10.0),
        // Строка задания остаётся на месте всегда: исчезнувшее поле прораб
        // читает как «не загрузилось», а тут загружать нечего — диспетчер
        // завёл заявку по звонку и текст не написал.
        WorkFact(
          name: 'Задание',
          value: task ?? 'Задание не описано',
          faint: task == null,
        ),
        WorkFact(name: 'Категория', value: order.categoryLabel),
        // Причину неисправности заполняют, когда разобрались: у идущей заявки
        // её обычно нет, и пустая строка сказала бы, что механик молчит.
        if (reason != null) WorkFact(name: 'Причина', value: reason),
        if (created != null) WorkFact(name: 'Заведена', value: created),
        if (photos.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: photos
                .map((String photo) => _Thumb(photo: photo))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class WorkFact extends StatelessWidget {
  const WorkFact({
    Key? key,
    required this.name,
    required this.value,
    this.faint = false,
  }) : super(key: key);

  final String name;
  final String value;

  /// Серым — то, чего система не записала вовсе.
  final bool faint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130.0,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.0,
                color: faint ? ColorApp.myColorGrayText : ColorApp.myColorBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkBlockTitle extends StatelessWidget {
  const WorkBlockTitle({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        color: ColorApp.myColorGray,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Подробности не приехали. Шапка при этом на месте: всё, что в ней есть,
/// пришло со строкой списка и серверу не нужно.
class WorkFailureBlock extends StatelessWidget {
  const WorkFailureBlock({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Чек-лист и снимки недоступны. То, что видно в списке, — на месте.',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
        const SizedBox(height: 12.0),
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: ColorApp.myColorGreenAuth,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () => context
                  .read<WorkDetailsBloc>()
                  .add(const WorkDetailsRequested()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Text(
                  'Повторить',
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

/// Подробности едут. Серые заготовки вместо крутилки — блок занимает своё
/// место сразу, и карточка не подпрыгивает, когда чек-лист приедет.
class WorkSkeleton extends StatelessWidget {
  const WorkSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(
        5,
        (int index) => Container(
          height: 12.0,
          width: index.isEven ? double.infinity : 180.0,
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: ColorApp.myColorGrayShadow,
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
    );
  }
}

