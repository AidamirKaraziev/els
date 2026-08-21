import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../bloc/in_progress_works_bloc.dart';
import '../models/in_progress_work.dart';
import 'in_progress_work_row.dart';

/// Красная пометка в заголовке — единственное красное пятно вне бейджа аварии.
const Color _flagColor = Color(0xffC25551);

/// Раздел «Сейчас в работе» над лентой сданных работ.
///
/// Живёт своим запросом: если ручка текущих работ не ответила, на её месте
/// появляется тихая строка, а лента сданных грузится как обычно.
class InProgressSection extends StatelessWidget {
  const InProgressSection({Key? key, required this.state}) : super(key: key);

  final InProgressWorksState state;

  @override
  Widget build(BuildContext context) {
    final InProgressWorksState state = this.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Число работ у заголовка есть только тогда, когда список на руках:
        // в загрузке и в сбое показывать нечего, а ноль был бы враньём.
        _Title(works: state is InProgressWorksFailure ? null : state.works),
        const SizedBox(height: 12.0),
        ..._body(state),
      ],
    );
  }

  List<Widget> _body(InProgressWorksState state) {
    if (state is InProgressWorksFailure) {
      return <Widget>[
        // Текст сбоя берём у репозитория: «не удалось загрузить» и «истёк
        // вход» лечатся по-разному, и подменять одно другим нельзя.
        _Message(
          title: state.message,
          subtitle: 'Проверьте связь и попробуйте ещё раз. Сданные работы '
              'ниже — они на месте.',
        ),
      ];
    }

    final InProgressWorks? works = state.works;
    if (works == null) return const <Widget>[_Skeleton()];

    if (works.isEmpty) {
      return const <Widget>[
        _Message(
          title: 'Сейчас никто не работает',
          subtitle: 'Здесь появятся ТО и заявки, за которые механики '
              'взялись — сразу, как они начнут.',
        ),
      ];
    }

    // Список режет сервер, а не экран: он же считает, сколько работ не
    // поместилось. Реши это экран сам — он не знал бы про отрезанные строки
    // ничего, кроме того, что их нет.
    final int hidden = works.hidden;

    return <Widget>[
      ...works.items.map(
        (InProgressWork work) => InProgressWorkRow(
          work: work,
          // Карточка работы приезжает этапом 9.1; до неё строка подсвечивается
          // нажатием, но никуда не ведёт.
          onTap: null,
        ),
      ),
      if (hidden > 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Center(
            child: Text(
              'и ещё $hidden',
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
        ),
    ];
  }
}

/// «Сейчас в работе · 4 · 1 проблема».
///
/// Число работ серым рядом с заголовком, красная пометка справа — если среди
/// них есть проблема. Нажимать на пометку некуда: проблемные работы и так
/// стоят первыми прямо под ней.
class _Title extends StatelessWidget {
  const _Title({Key? key, required this.works}) : super(key: key);

  final InProgressWorks? works;

  @override
  Widget build(BuildContext context) {
    final int? total = works?.total;
    final int problems = works?.problems ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        const Text(
          'Сейчас в работе',
          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700),
        ),
        if (total != null) ...<Widget>[
          const SizedBox(width: 8.0),
          Text(
            '$total',
            style: const TextStyle(
              fontSize: 15.0,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
        const Spacer(),
        if (problems > 0)
          Text(
            _problemsLabel(problems),
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: _flagColor,
            ),
          ),
      ],
    );
  }
}

/// «1 проблема», «3 проблемы», «5 проблем».
String _problemsLabel(int count) {
  final int hundreds = count % 100;
  final int tens = count % 10;
  if (hundreds >= 11 && hundreds <= 14) return '$count проблем';
  if (tens == 1) return '$count проблема';
  if (tens >= 2 && tens <= 4) return '$count проблемы';
  return '$count проблем';
}

/// Пустой раздел и сбой загрузки. Оформление — как у пустой ленты сданных
/// работ: раздел остаётся на месте, потому что исчезнувший читается как
/// поломка, а прыгающая при каждом обновлении лента — как мигание.
class _Message extends StatelessWidget {
  const _Message({Key? key, required this.title, required this.subtitle})
      : super(key: key);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4.0),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.0,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Первая загрузка. Серые заготовки вместо крутилки: раздел занимает своё
/// место сразу, и лента сданных не подпрыгивает, когда строки приедут.
class _Skeleton extends StatelessWidget {
  const _Skeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        2,
        (_) => Container(
          height: 58.0,
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: ColorApp.myColorGrayShadow,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }
}
