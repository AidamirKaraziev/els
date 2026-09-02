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
