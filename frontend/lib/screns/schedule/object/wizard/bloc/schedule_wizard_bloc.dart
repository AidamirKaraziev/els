import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../repository/schedules_repository.dart';
import '../models/schedule_wizard_data.dart';
import '../repository/schedule_wizard_repository.dart';

part 'schedule_wizard_event.dart';
part 'schedule_wizard_state.dart';

/// Мастер расстановки годового графика: откуда берётся заготовка.
///
/// До этой работы мастер жил на фикстуре и держал шаг в `setState`. С живой
/// ручкой появились загрузка, ошибка и перезапрос при смене месяца — три
/// состояния, которые в `setState` пришлось бы держать руками.
///
/// Месяц начала цикла экран не считает и не угадывает: он либо приходит с
/// сервера, восстановленный по прошлому году, либо его называет человек.
class ScheduleWizardBloc extends Bloc<ScheduleWizardEvent, ScheduleWizardState> {
  ScheduleWizardBloc({
    required ScheduleWizardRepository repository,
    required this.objectId,
    required this.year,
  })  : _repository = repository,
        super(const ScheduleWizardInitial()) {
    on<WizardOpened>(_onOpened);
    on<WizardAnchorChanged>(_onAnchorChanged);
  }

  final ScheduleWizardRepository _repository;
  final int objectId;
  final int year;

  /// Месяц, который мастер показывает, когда сервер отказался подбирать его
  /// сам. Январь — видимое умолчание, а не молча применённый сдвиг: человек
  /// его видит на шаге «Точка отсчёта» и может поменять.
  static const int _defaultAnchor = 1;

  Future<void> _onOpened(
    WizardOpened event,
    Emitter<ScheduleWizardState> emit,
  ) async {
    emit(const ScheduleWizardLoading());
    try {
      // Сначала без якоря: у объекта с прошлогодним графиком цикл продолжается
      // сам, и спрашивать человека не о чем — шаг «Точка отсчёта» отпадает.
      final ScheduleWizardData data = await _repository.preview(objectId, year);
      emit(ScheduleWizardLoaded(
        data: data,
        anchorMonth: data.previousYearAnchor ?? _defaultAnchor,
      ));
    } on ScheduleAnchorRequiredException {
      // Якорь не восстановился. Это не ошибка экрана: заготовку всё равно
      // показываем — с января, — а месяц человек выбирает на шаге 2.
      await _load(emit, _defaultAnchor);
    } on SchedulesException catch (error) {
      emit(ScheduleWizardFailure(error.message));
    } catch (_) {
      emit(const ScheduleWizardFailure('Не удалось построить заготовку графика'));
    }
  }

  Future<void> _onAnchorChanged(
    WizardAnchorChanged event,
    Emitter<ScheduleWizardState> emit,
  ) async {
    final ScheduleWizardState current = state;
    if (current is! ScheduleWizardLoaded) return;
    if (current.anchorMonth == event.month) return;

    // Заготовку на время запроса оставляем на экране: человек только что
    // ткнул в месяц и смотрит, что изменится в ленте. Пустой экран на этом
    // месте читался бы как «мастер сбросился».
    emit(current.copyWith(anchorMonth: event.month, isReloading: true));
    await _load(emit, event.month, previous: current);
  }

  /// Запрос заготовки с названным месяцем.
  ///
  /// [previous] — что показывать, если запрос не удался: заготовку с прежним
  /// якорем терять незачем, ошибка живёт рядом с ней.
  Future<void> _load(
    Emitter<ScheduleWizardState> emit,
    int anchorMonth, {
    ScheduleWizardLoaded? previous,
  }) async {
    try {
      final ScheduleWizardData data = await _repository.preview(
        objectId,
        year,
        anchorMonth: anchorMonth,
      );
      emit(ScheduleWizardLoaded(data: data, anchorMonth: anchorMonth));
    } on SchedulesException catch (error) {
      emit(_failed(previous, error.message));
    } catch (_) {
      emit(_failed(previous, 'Не удалось построить заготовку графика'));
    }
  }

  /// Неудача запроса. С прежней заготовкой на руках возвращаем её целиком —
  /// вместе с прежним месяцем: показывать ленту старого якоря под подписью
  /// нового значило бы врать про то, что человек выбрал.
  ScheduleWizardState _failed(ScheduleWizardLoaded? previous, String message) {
    if (previous == null) return ScheduleWizardFailure(message);
    return previous.copyWith(error: message);
  }
}
