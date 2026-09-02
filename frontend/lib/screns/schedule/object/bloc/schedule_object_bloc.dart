import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/month_cell.dart';
import '../../repository/schedules_repository.dart';
import '../models/schedule_object_card.dart';
import '../repository/schedule_object_repository.dart';

part 'schedule_object_event.dart';
part 'schedule_object_state.dart';

/// Экран графика объекта: карточка и годовая лента.
///
/// Репозиторий обязателен: подставлять сюда сетевой по умолчанию нечего —
/// экран открывается и на фикстуре, и молчаливая подмена выглядела бы как
/// пустой экран без единой ошибки.
class ScheduleObjectBloc extends Bloc<ScheduleObjectEvent, ScheduleObjectState> {
  ScheduleObjectBloc({
    required ScheduleObjectRepository repository,
    required this.objectId,
    int? initialYear,
  })  : _repository = repository,
        _year = initialYear ?? DateTime.now().year,
        super(const ScheduleObjectInitial()) {
    on<ScheduleObjectRequested>(_onRequested);
    on<ScheduleObjectYearRequested>(_onYearRequested);
    on<ScheduleObjectCellMoved>(_onCellMoved);
    // ignore: deprecated_member_use_from_same_package
    on<ScheduleObjectGenerateRequested>(_onGenerateRequested);
  }

  final ScheduleObjectRepository _repository;
  final int objectId;

  /// Показанный год. Держим полем, а не только в состоянии: первая загрузка
  /// стартует с него ещё до того, как состояние «загружено» появилось.
  int _year;

  Future<void> _onRequested(
    ScheduleObjectRequested event,
    Emitter<ScheduleObjectState> emit,
  ) async {
    emit(const ScheduleObjectLoading());
    try {
      final ScheduleObjectCard card = await _repository.fetchCard(objectId);
      // Лента запрашивается после карточки, а не вместе с ней: не пришла
      // лента — экран всё равно показывает объект, и это лучше, чем ошибка
      // во весь экран из-за одной ручки графика.
      emit(ScheduleObjectLoaded(
        card: card,
        year: _year,
        cells: _emptyYear(),
        isYearLoading: true,
      ));
      await _loadYear(emit, _year);
    } on SchedulesException catch (error) {
      emit(ScheduleObjectFailure(error.message));
    } catch (_) {
      emit(const ScheduleObjectFailure('Не удалось загрузить объект'));
    }
  }

  Future<void> _onYearRequested(
    ScheduleObjectYearRequested event,
    Emitter<ScheduleObjectState> emit,
  ) async {
    final ScheduleObjectState current = state;
    if (current is! ScheduleObjectLoaded) return;

    _year = event.year;
    // Клетки прошлого года гасим сразу: показывать чужие цвета под новой
    // подписью года нельзя — это прямая неправда о состоянии объекта.
    emit(current.copyWith(
      year: event.year,
      cells: _emptyYear(),
      isYearLoading: true,
    ));
    await _loadYear(emit, event.year);
  }

  Future<void> _onCellMoved(
    ScheduleObjectCellMoved event,
    Emitter<ScheduleObjectState> emit,
  ) async {
    final ScheduleObjectState current = state;
    if (current is! ScheduleObjectLoaded) return;

    final int? actId = event.cell.actId;
    final int fromMonth = event.cell.month;
    final int toMonth = event.toMonth;
    if (actId == null || fromMonth == toMonth) return;
    // Занятый месяц не принимает: лента такую цель и не подсвечивает, но
    // событие может прийти и не от неё.
    if (current.cells[toMonth - 1].status != MonthStatus.none) return;

    final int year = current.year;

    // Клетка переезжает сразу, до ответа сервера: перетаскивание, после
    // которого полсекунды ничего не двигается, читается как несработавшее, и
    // человек тащит второй раз. Неудача вернёт ленту на место — её всё равно
    // перечитываем с сервера.
    emit(current.copyWith(cells: _moved(current.cells, event.cell, toMonth)));

    try {
      await _repository.moveCell(
        objectId,
        year,
        actId: actId,
        fromMonth: fromMonth,
        toMonth: toMonth,
      );
    } on SchedulesException catch (error) {
      await _reloadAfterFailedMove(emit, year, error.message);
      return;
    } catch (_) {
      await _reloadAfterFailedMove(emit, year, 'Не удалось перенести ТО');
      return;
    }

    // Состояние перенесённой клетки — «назначено» или «просрочено» — считает
    // сервер по новому месяцу, и спрашиваем его, а не пересчитываем сами.
    await _loadYear(emit, year);
  }

  /// Перенос не удался: сказать об этом и показать то, что в базе.
  Future<void> _reloadAfterFailedMove(
    Emitter<ScheduleObjectState> emit,
    int year,
    String message,
  ) async {
    final ScheduleObjectState current = state;
    if (current is ScheduleObjectLoaded && current.year == year) {
      emit(current.copyWith(yearError: message, isYearLoading: true));
    }
    await _loadYear(emit, year);
    final ScheduleObjectState after = state;
    // `_loadYear` затирает ошибку своим `copyWith` — возвращаем её на место:
    // лента снова верна, но сказать, что перенос не прошёл, всё равно надо.
    if (after is ScheduleObjectLoaded && after.year == year) {
      emit(after.copyWith(yearError: message));
    }
  }

  /// Лента с ТО, переехавшим на другой месяц.
  List<MonthCell> _moved(List<MonthCell> cells, MonthCell cell, int toMonth) {
    return <MonthCell>[
      for (final MonthCell item in cells)
        if (item.month == toMonth)
          MonthCell(
            month: toMonth,
            status: cell.status,
            toName: cell.toName,
            actId: cell.actId,
          )
        else if (item.month == cell.month)
          MonthCell.empty(item.month)
        else
          item,
    ];
  }

  Future<void> _onGenerateRequested(
    ScheduleObjectGenerateRequested event,
    Emitter<ScheduleObjectState> emit,
  ) async {
    final ScheduleObjectState current = state;
    if (current is! ScheduleObjectLoaded) return;
    if (current.isGenerating) return;

    final int year = current.year;
    emit(current.copyWith(isGenerating: true));
    try {
      // ignore: deprecated_member_use_from_same_package
      await _repository.generateYear(objectId, year);
    } on SchedulesException catch (error) {
      emit(_latest(current).copyWith(isGenerating: false, yearError: error.message));
      return;
    } catch (_) {
      emit(_latest(current).copyWith(
        isGenerating: false,
        yearError: 'Не удалось создать график',
      ));
      return;
    }

    // Что именно легло в месяцы, спрашиваем у ленты, а не разбираем ответ
    // создания: состояние клетки считает сервер.
    emit(_latest(current).copyWith(isGenerating: false, isYearLoading: true));
    await _loadYear(emit, year);
  }

  /// Запросить клетки года и показать их, если год не переключили заново.
  Future<void> _loadYear(Emitter<ScheduleObjectState> emit, int year) async {
    try {
      final List<MonthCell> cells = await _repository.fetchYear(objectId, year);
      final ScheduleObjectState current = state;
      if (current is! ScheduleObjectLoaded || current.year != year) {
        // Человек успел щёлкнуть стрелку ещё раз: ответ за прошлый год
        // выбрасываем, иначе лента показала бы не тот год, что в подписи.
        return;
      }
      emit(current.copyWith(cells: cells, isYearLoading: false));
    } on SchedulesException catch (error) {
      _emitYearError(emit, year, error.message);
    } catch (_) {
      _emitYearError(emit, year, 'Не удалось загрузить график за $year год');
    }
  }

  void _emitYearError(Emitter<ScheduleObjectState> emit, int year, String message) {
    final ScheduleObjectState current = state;
    if (current is! ScheduleObjectLoaded || current.year != year) return;
    emit(current.copyWith(isYearLoading: false, yearError: message));
  }

  /// Свежее «загружено» — или то, с которого начинали, если состояние успело
  /// смениться на другое.
  ScheduleObjectLoaded _latest(ScheduleObjectLoaded fallback) {
    final ScheduleObjectState current = state;
    return current is ScheduleObjectLoaded ? current : fallback;
  }

  List<MonthCell> _emptyYear() =>
      <MonthCell>[for (int month = 1; month <= 12; month++) MonthCell.empty(month)];
}
