import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../bloc/schedules_bloc.dart';
import '../models/month_cell.dart';
import '../models/schedule_filters.dart';
import '../models/schedule_role.dart';
import '../models/schedule_row.dart';
import '../widgets/schedule_filters_bar.dart';
import '../widgets/schedule_row_tile.dart';
import 'schedule_object_opener.dart';
import 'schedule_section.dart';
import 'schedule_work_card_screen.dart';

// Перечисление переехало в `models/schedule_role.dart`: его берёт и экран
// объекта. Реэкспорт оставлен, чтобы места встраивания (`home_page.dart`,
// `home_foreman.dart`) и тесты продолжали видеть его здесь.
export '../models/schedule_role.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({
    Key? key,
    this.role = ScheduleRole.admin,
    this.drawer = const MyDrawer(),
    this.opener,
  }) : super(key: key);

  final ScheduleRole role;

  /// Чем открывать экран «График» по клику в строку.
  ///
  /// Приходит снаружи, от оболочки: сам экран живёт на её номерах экранов, и
  /// лента о них знать не должна. Пусто — клик по строке ничего не делает;
  /// так лента собирается в тесте и не лезет ни в сеть, ни в глобальные
  /// переменные подрядчика.
  final ScheduleObjectOpener? opener;

  /// Боковое меню приложения. У прораба лента — корень раздела, и на узкой
  /// ширине это единственный способ уйти из «Графиков» куда-то ещё.
  final Widget drawer;

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  /// За сколько пикселей до конца списка просить следующую страницу.
  static const double _loadMoreThreshold = 300;

  late ScrollController _scrollController;
  late SchedulesBloc _bloc;

  /// Идёт подготовка экрана «График»: четыре запроса подряд.
  ///
  /// Пока они идут, лента закрыта индикатором. Иначе человек, не увидев
  /// отклика, жмёт вторую строку — и уезжает на объект, которого не выбирал.
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _bloc = context.read<SchedulesBloc>();
    _bloc.add(SchedulesRequested(filters: _bloc.state.filters));
    // Значения выпадающих просим отдельно и один раз: они не меняются от того,
    // какой отбор сейчас стоит и какая страница открыта.
    _bloc.add(const SchedulesFilterOptionsRequested());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Догрузка следующей страницы.
  ///
  /// Порог в пикселях, а не «доскроллил до самого низа»: страница должна
  /// успеть приехать до того, как человек упрётся в конец списка.
  ///
  /// Состояние берём у блока, а не из замыкания над тем, что нарисовал
  /// `BlocBuilder`: слушатель живёт дольше одной отрисовки и с чужим снимком
  /// послал бы второй запрос за уже загруженной страницей.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) return;

    final SchedulesState state = _bloc.state;
    if (state is! SchedulesLoaded) return;
    if (!state.hasNext || state.isLoadingMore) return;

    _bloc.add(const SchedulesNextPageRequested());
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

  /// Клик мимо клеток открывает экран «График» этого объекта.
  ///
  /// Экран показывает все годы объекта сразу и своего года не выбирает —
  /// год, выбранный в ленте, ему не передаём.
  Future<void> _onRowTap(ScheduleRow row) async {
    final ScheduleObjectOpener? opener = widget.opener;
    if (opener == null || _opening) return;

    setState(() => _opening = true);
    try {
      await opener.open(row);
    } catch (_) {
      // Текст ошибки не показываем: за ним стоит ответ ручки, человеку он
      // ничего не объясняет. Важно другое — он остался в ленте, а не смотрит
      // на пустой экран графика.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть график: ${row.nameLabel}')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
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
      drawer: widget.drawer,
      appBar: AppBar(
        automaticallyImplyLeading: scheduleShowsLeading(context),
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
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _body(state),
                    // Заслонка поверх ленты, а не вместо неё: список остаётся
                    // на месте, и после ошибки человек видит то же, что и до
                    // клика.
                    if (_opening) ...<Widget>[
                      const ModalBarrier(dismissible: false, color: Colors.black12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
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
        child: Builder(
          builder: (BuildContext context) {
            // Подвал считаем до списка: когда его нет, нет и лишней строки, а
            // значит нет разделителя, висящего под последним объектом.
            final Widget? footer = _footer(state);

            return ListView.separated(
              controller: _scrollController,
              itemCount: state.rows.length + (footer == null ? 0 : 1),
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(
                height: 1,
                thickness: 1,
                color: ColorApp.myColorGrayBorder,
              ),
              itemBuilder: (BuildContext context, int index) {
                if (index == state.rows.length) return footer!;

                final ScheduleRow row = state.rows[index];

                return ScheduleRowTile(
                  row: row,
                  onCellTap: _onCellTap,
                  onRowTap: widget.opener == null ? null : () => _onRowTap(row),
                );
              },
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Что стоит под последним объектом: спиннер догрузки, отбивка «это всё» или
  /// ничего.
  ///
  /// Подпись показываем только после реальной догрузки (`page > 1`): под
  /// списком из трёх объектов «Это все объекты» звучит как отчёт о проделанной
  /// работе там, где листать было нечего.
  Widget? _footer(SchedulesLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!state.hasNext && state.page > 1) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Это все объекты',
            style: TextStyle(
              fontSize: 13,
              color: ColorApp.myColorGrayText,
            ),
          ),
        ),
      );
    }

    return null;
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
