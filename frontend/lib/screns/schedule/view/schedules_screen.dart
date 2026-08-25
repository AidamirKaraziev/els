import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../bloc/schedules_bloc.dart';
import '../models/month_cell.dart';
import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';
import '../widgets/schedule_filters_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bloc = context.read<SchedulesBloc>();
    _bloc.add(SchedulesRequested(filters: _bloc.state.filters));
    // Значения выпадающих просим отдельно и один раз: они не меняются от того,
    // какой отбор сейчас стоит и какая страница открыта.
    _bloc.add(const SchedulesFilterOptionsRequested());
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

  /// Любая перемена отбора — фильтр, год или поиск — это один и тот же запрос
  /// с первой страницы.
  void _onFiltersChanged(ScheduleFilters filters) {
    _bloc.add(SchedulesRequested(filters: filters));
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
      body: BlocBuilder<SchedulesBloc, SchedulesState>(
        builder: (BuildContext context, SchedulesState state) {
          return Column(
            children: <Widget>[
              // Панель рисуется во всех состояниях, включая загрузку и ошибку:
              // фильтр применяется сразу при выборе, и пропадай панель на время
              // запроса — выбрать второй фильтр было бы не по чему.
              ScheduleFiltersBar(
                filters: state.filters,
                options: state.options,
                onChanged: _onFiltersChanged,
              ),
              Expanded(child: _body(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(SchedulesState state) {
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
        return _EmptyView(
          filters: state.filters,
          onReset: () => _onFiltersChanged(state.filters.cleared()),
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
          itemCount: state.rows.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (BuildContext context, int index) => const Divider(
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
  }
}

/// Пустая выдача.
///
/// Два разных случая, и путать их нельзя: объектов нет вовсе — это про базу,
/// а «ничего не нашлось» — про отбор, который человек сам только что и сузил.
/// Раньше в обоих случаях висело одинаковое «Объектов не найдено», и виноватым
/// выглядела система.
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    Key? key,
    required this.filters,
    required this.onReset,
  }) : super(key: key);

  final ScheduleFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final bool filtered = !filters.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              filtered ? Icons.search_off : Icons.inbox_outlined,
              size: 48,
              color: ColorApp.myColorGrayBorder,
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'Под отбор за ${filters.year} год не подошёл ни один объект'
                  : 'Объектов не найдено',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorApp.myColorGrayText,
              ),
            ),
            if (filtered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Стоит условий: ${filters.activeCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorApp.myColorGrayText,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Сбросить всё',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorApp.myColorGreenAuth,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
