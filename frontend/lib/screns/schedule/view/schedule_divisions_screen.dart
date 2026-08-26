import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../bloc/schedule_divisions_bloc.dart';
import '../bloc/schedules_bloc.dart';
import '../models/schedule_division.dart';
import '../models/schedule_filters.dart';
import '../widgets/schedule_division_tile.dart';
import '../widgets/schedule_year_picker.dart';
import 'schedule_section.dart';
import 'schedules_screen.dart';

/// Первое окно «Графиков» у админа: участки за выбранный год.
///
/// Прораб сюда не попадает — у него участок один, и лишний клик перед лентой
/// объектов был бы платой ни за что. Развилку держит `ScheduleSection`.
class ScheduleDivisionsScreen extends StatefulWidget {
  const ScheduleDivisionsScreen({
    Key? key,
    this.drawer = const MyDrawer(),
  }) : super(key: key);

  /// Боковое меню приложения. Раздел живёт внутри оболочки, у которой на узкой
  /// ширине меню открывается только из экрана — без этого человек с телефона
  /// проваливается в «Графики» и остаётся там без навигации.
  final Widget drawer;

  @override
  State<ScheduleDivisionsScreen> createState() =>
      _ScheduleDivisionsScreenState();
}

class _ScheduleDivisionsScreenState extends State<ScheduleDivisionsScreen> {
  late ScheduleDivisionsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ScheduleDivisionsBloc>();
    _bloc.add(ScheduleDivisionsRequested(year: _bloc.state.year));
  }

  void _onYearChanged(int year) {
    _bloc.add(ScheduleDivisionsRequested(year: year));
  }

  /// Клик по участку открывает ту же ленту объектов, но с проставленным
  /// фильтром «Участок» и выбранным годом.
  ///
  /// Блок создаётся здесь, свой на каждый заход: вернувшись назад и выбрав
  /// другой участок, человек должен получить чистый отбор, а не остатки
  /// предыдущего.
  void _openDivision(ScheduleDivision division, int year) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BlocProvider<SchedulesBloc>(
          create: (_) => SchedulesBloc(
            filters: ScheduleFilters(
              year: year,
              division: FilterOption(
                id: division.divisionId,
                title: division.title,
              ),
            ),
          ),
          child: SchedulesScreen(
            role: ScheduleRole.admin,
            drawer: widget.drawer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleDivisionsBloc, ScheduleDivisionsState>(
      builder: (BuildContext context, ScheduleDivisionsState state) {
        return Scaffold(
          backgroundColor: ColorApp.myColorGrayShadow,
          drawer: widget.drawer,
          appBar: AppBar(
              automaticallyImplyLeading: scheduleShowsLeading(context),
              title: const Text('Графики'),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: ColorApp.myColorBlack,
              actions: <Widget>[
                // Переключатель рисуется во всех состояниях, включая загрузку:
                // иначе на время запроса из шапки пропадал бы сам год.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: ScheduleYearPicker(
                      year: state.year,
                      onChanged: _onYearChanged,
                    ),
                  ),
                ),
              ],
            ),
          body: _body(state),
        );
      },
    );
  }

  Widget _body(ScheduleDivisionsState state) {
    if (state is ScheduleDivisionsInitial ||
        state is ScheduleDivisionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ScheduleDivisionsFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ScheduleDivisionsLoaded) {
      if (state.divisions.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: ColorApp.myColorGrayBorder,
                ),
                const SizedBox(height: 16),
                Text(
                  'За ${state.year} год участков нет',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Одна белая карточка на сером фоне, строки разделены линией — та же
      // раскладка, что у ленты объектов.
      return SingleChildScrollView(
        child: Container(
        margin: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.divisions.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(
            height: 1,
            thickness: 1,
            color: ColorApp.myColorGrayBorder,
          ),
          itemBuilder: (BuildContext context, int index) {
            return ScheduleDivisionTile(
              division: state.divisions[index],
              onTap: (ScheduleDivision division) =>
                  _openDivision(division, state.year),
            );
          },
        ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
