import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../bloc/schedules_bloc.dart';
import '../models/month_cell.dart';
import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';
import '../widgets/schedule_row_tile.dart';
import 'schedule_work_card_screen.dart';

enum ScheduleRole { admin, foreman }

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({
    Key? key,
    this.role = ScheduleRole.admin,
  }) : super(key: key);

  final ScheduleRole role;

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  late ScrollController _scrollController;
  late SchedulesBloc _bloc;
  int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bloc = context.read<SchedulesBloc>();
    _bloc.add(
      SchedulesRequested(
        filters: ScheduleFilters(year: _currentYear),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Клик по клетке открывает карточку работы за ней.
  ///
  /// Название объекта берём из строки, а не из клетки: в шапке карточки должно
  /// стоять «ТЦ Карнавал 3 этаж 1», иначе человек, провалившийся из ленты,
  /// видит безымянную «Работу» и не понимает, чью именно он открыл.
  void _onCellTap(ScheduleRow row, MonthCell cell) {
    if (!cell.isTappable) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ScheduleWorkCardScreen(
          workId: cell.actId!,
          objectName: row.nameLabel,
        ),
      ),
    );
  }

  void _onYearChanged(int year) {
    setState(() => _currentYear = year);
    _bloc.add(
      SchedulesRequested(
        filters: ScheduleFilters(year: year),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Фон серый, карточка списка белая — иначе карточки на экране не видно.
      backgroundColor: ColorApp.myColorGrayShadow,
      appBar: AppBar(
        title: const Text('Графики'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: ColorApp.myColorBlack,
      ),
      body: Column(
        children: [
          _YearSelector(
            year: _currentYear,
            onYearChanged: _onYearChanged,
          ),
          Expanded(
            child: BlocBuilder<SchedulesBloc, SchedulesState>(
              builder: (BuildContext context, SchedulesState state) {
                if (state is SchedulesInitial || state is SchedulesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SchedulesFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SchedulesLoaded) {
                  if (state.rows.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: ColorApp.myColorGrayBorder),
                          SizedBox(height: 16),
                          Text(
                            'Объектов не найдено',
                            style: TextStyle(fontSize: 14, color: ColorApp.myColorGrayText),
                          ),
                        ],
                      ),
                    );
                  }

                  // Список — одна белая карточка на сером фоне, как в кадре
                  // `83:312`. Строки внутри разделены линией, а не отступом:
                  // отступ между белыми строками на белой карточке не виден.
                  return Container(
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: ColorApp.myColorWhite,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount:
                          state.rows.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(
                        height: 1,
                        thickness: 1,
                        color: ColorApp.myColorGrayBorder,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == state.rows.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        return ScheduleRowTile(
                          row: state.rows[index],
                          onCellTap: _onCellTap,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    Key? key,
    required this.year,
    required this.onYearChanged,
  }) : super(key: key);

  final int year;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: ColorApp.myColorGrayShadow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onYearChanged(year - 1),
          ),
          Text(
            '$year',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onYearChanged(year + 1),
          ),
        ],
      ),
    );
  }
}
