import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_user.dart';
import '../../in_progress_works/bloc/in_progress_works_bloc.dart';
import '../../in_progress_works/widgets/in_progress_works_live.dart';
import '../bloc/submitted_works_bloc.dart';
import '../models/submitted_work.dart';
import '../unreviewed_counter.dart';
import '../widgets/submitted_work_row.dart';
import 'submitted_work_card_screen.dart';

/// Экран прораба: что механики ведут прямо сейчас и что уже сдали.
///
/// Две ленты в одной прокрутке. Сверху раздел «Сейчас в работе» — работы, в
/// которые можно вмешаться сегодня; ниже, за разделителем, привычная лента
/// сданных с фильтром, кнопками «Проверил» и страницами. Запроса два, экран
/// для прораба один.
///
/// Своего кадра в макете нет — дизайнер рисовал только экраны руководителя и
/// телефон механика, — поэтому экран собран из приёмов соседних кадров: белая
/// шапка с заголовком, серые строки списка, цвет только на бейджах. Тот же
/// путь, что и у раздела «Отчёты».
class SubmittedWorksScreen extends StatelessWidget {
  const SubmittedWorksScreen({Key? key, this.drawer}) : super(key: key);

  /// Боковое меню роли. Экран не знает, кто его открыл: у прораба и у админа
  /// меню разные, а лента одна.
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    // Два блока рядом, а не один на оба списка: ручки разные, и сбой раздела
    // не должен гасить ленту сданных работ.
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubmittedWorksBloc>(
          create: (_) =>
              SubmittedWorksBloc()..add(const SubmittedWorksRequested(page: 1)),
        ),
        BlocProvider<InProgressWorksBloc>(
          create: (_) =>
              InProgressWorksBloc()..add(const InProgressWorksRequested()),
        ),
      ],
      child: _SubmittedWorksView(drawer: drawer),
    );
  }
}

class _SubmittedWorksView extends StatelessWidget {
  const _SubmittedWorksView({Key? key, this.drawer}) : super(key: key);

  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      key: myOpenDrawer,
      drawer: drawer,
      backgroundColor: ColorApp.myColorTransparent,
      body: BlocConsumer<SubmittedWorksBloc, SubmittedWorksState>(
        listener: (BuildContext context, SubmittedWorksState state) {
          if (state is SubmittedWorksActionFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (BuildContext context, SubmittedWorksState state) {
          return Column(
            children: <Widget>[
              _Header(size: size, hasDrawer: drawer != null),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  children: <Widget>[
                    // Раздел текущих работ живёт своим блоком: его загрузка и
                    // его сбой ленты сданных не касаются. Перечитывает он себя
                    // сам, раз в минуту, — лента сданных так не умеет, там
                    // страницы и фильтр, которые сбрасывать под руками нельзя.
                    const InProgressWorksLive(),
                    const _SectionDivider(),
                    _FiltersBar(state: state),
                    const SizedBox(height: 16.0),
                    ..._body(context, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, SubmittedWorksState state) {
    if (state is SubmittedWorksFailure) {
      return <Widget>[
        _Message(
          icon: Icons.cloud_off_outlined,
          title: state.message,
          action: 'Повторить',
          onAction: () => context
              .read<SubmittedWorksBloc>()
              .add(const SubmittedWorksRequested()),
        ),
      ];
    }

    final SubmittedWorksPage? page = state.page;
    if (page == null) {
      return const <Widget>[
        SizedBox(height: 80.0),
        Center(child: CircularProgressIndicator()),
      ];
    }

    final bool loading = state is SubmittedWorksLoading;

    if (page.isEmpty) {
      return <Widget>[
        _Message(
          icon: Icons.inbox_outlined,
          title: state.onlyUnreviewed
              ? 'Непросмотренных работ нет'
              : 'Сданных работ пока нет',
          subtitle: state.onlyUnreviewed
              ? 'Всё, что механики сдали, вы уже посмотрели.'
              : 'Здесь появятся закрытые ТО и заявки — сразу, как механик '
                  'закроет работу в телефоне.',
        ),
      ];
    }

    return <Widget>[
      Opacity(
        opacity: loading ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...page.items.map(
              (SubmittedWork work) => SubmittedWorkRow(
                work: work,
                // Пока идёт запрос, кнопки не жмутся: второй клик по той же
                // строке ничего не изменит, а мигание списка выглядит как сбой.
                onReview: loading
                    ? null
                    : () => context
                        .read<SubmittedWorksBloc>()
                        .add(SubmittedWorkReviewed(work)),
                // Карточка открывается и во время запроса: читать сданную
                // работу можно всегда, а перезапрос ленты её не касается.
                onOpen: () => _openCard(context, work),
              ),
            ),
            if (page.pageCount > 1) ...<Widget>[
              const SizedBox(height: 8.0),
              _Pager(page: page, loading: loading),
            ],
          ],
        ),
      ),
    ];
  }

  /// Карточка сданной работы поверх ленты.
  ///
  /// Отметку она делает не сама: событие уходит в тот же блок ленты, что и у
  /// кнопки в строке. Строка чинится на месте, страница перезапрашивается,
  /// счётчик в меню обновляет репозиторий — к возврату прораба лента уже
  /// верна, а карточка не знает про сеть ничего лишнего.
  void _openCard(BuildContext context, SubmittedWork work) {
    final SubmittedWorksBloc bloc = context.read<SubmittedWorksBloc>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SubmittedWorkCardScreen(
          work: work,
          onReview: () => bloc.add(SubmittedWorkReviewed(work)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key, required this.size, required this.hasDrawer})
      : super(key: key);

  final Size size;
  final bool hasDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
      color: ColorApp.myColorWhite,
      height: 70,
      width: double.infinity,
      child: Row(
        children: <Widget>[
          if (hasDrawer && size.width <= 1350)
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => myOpenDrawer.currentState?.openDrawer(),
                  icon: Icon(Icons.menu, size: size.width > 350 ? 25.0 : 20.0),
                ),
                const SizedBox(width: 10.0),
              ],
            ),
          Text(
            'Сданные работы',
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

/// Граница между двумя лентами: черта и подзаголовок.
///
/// Единственная граница — ни второй шапки, ни отступа в экран высотой:
/// прокрутка одна, и лента сданных не должна выглядеть отдельной страницей,
/// которую надо «закрыть».
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 4.0),
        Divider(color: ColorApp.myColorGrayBorder, height: 1.0),
        SizedBox(height: 12.0),
        Text(
          'Сданные работы',
          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.0),
      ],
    );
  }
}

/// Переключатель отбора и счётчик непросмотренного.
///
/// Счётчик тот же, что на кнопке меню: если бы экран считал своё число по
/// длине списка, оно расходилось бы с бейджем на второй же странице.
class _FiltersBar extends StatelessWidget {
  const _FiltersBar({Key? key, required this.state}) : super(key: key);

  final SubmittedWorksState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16.0,
        runSpacing: 8.0,
        children: <Widget>[
          FilterChip(
            label: const Text('Только непросмотренные'),
            selected: state.onlyUnreviewed,
            selectedColor: ColorApp.myColorGreenLine,
            backgroundColor: ColorApp.myColorTransparent,
            onSelected: (bool selected) => context
                .read<SubmittedWorksBloc>()
                .add(SubmittedWorksRequested(onlyUnreviewed: selected)),
          ),
          ValueListenableBuilder<int>(
            valueListenable: unreviewedWorksCount,
            builder: (BuildContext context, int count, _) => Text(
              count == 0
                  ? 'Непросмотренных нет'
                  : 'Не просмотрено: $count',
              style: const TextStyle(color: ColorApp.myColorGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({Key? key, required this.page, required this.loading})
      : super(key: key);

  final SubmittedWorksPage page;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    void go(int target) => context
        .read<SubmittedWorksBloc>()
        .add(SubmittedWorksRequested(page: target));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: page.hasPrev && !loading ? () => go(page.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Страница ${page.page} из ${page.pageCount}'),
        IconButton(
          onPressed: page.hasNext && !loading ? () => go(page.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 36.0, color: ColorApp.myColorGrayText),
          const SizedBox(height: 12.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6.0),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 16.0),
            TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
