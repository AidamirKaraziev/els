import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../repository/schedules_repository.dart';
import '../models/maintenance_program.dart';
import '../models/schedule_wizard_data.dart';
import '../repository/maintenance_program_repository.dart';
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
    required MaintenanceProgramRepository programRepository,
    required this.objectId,
    required this.year,
  })  : _repository = repository,
        _programs = programRepository,
        super(const ScheduleWizardInitial()) {
    on<WizardOpened>(_onOpened);
    on<WizardAnchorChanged>(_onAnchorChanged);
    on<WizardProgramSaved>(_onProgramSaved);
    on<WizardApproved>(_onApproved);
  }

  final ScheduleWizardRepository _repository;

  /// Куда уходит правка программы модели. Сама заготовка года после неё
  /// перезапрашивается: раскладку считает сервер, и держать рядом с ним свою
  /// правленую копию значило бы показывать не то, что ляжет в базу.
  final MaintenanceProgramRepository _programs;
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
    await _openPreview(emit);
  }

  /// Заготовка с нуля: то, с чего начинается и открытие мастера, и возврат
  /// после правки программы.
  ///
  /// [preferredAnchor] — месяц, который человек уже выбрал руками: после
  /// правки программы он остаётся в силе. Сервер о нём не знает и, не сумев
  /// восстановить якорь по базе, предложил бы январь — то есть молча сдвинул
  /// бы год, которого человека никто не спрашивал.
  Future<void> _openPreview(
    Emitter<ScheduleWizardState> emit, {
    int? preferredAnchor,
  }) async {
    try {
      // Сначала без якоря: у объекта с прошлогодним графиком цикл продолжается
      // сам, и спрашивать человека не о чем — шаг «Точка отсчёта» отпадает.
      final ScheduleWizardData data = await _repository.preview(objectId, year);
      emit(ScheduleWizardLoaded(
        data: data,
        anchorMonth: data.knownAnchor ?? _defaultAnchor,
      ));
    } on ScheduleAnchorRequiredException {
      // Якорь не восстановился. Это не ошибка экрана: заготовку всё равно
      // показываем — с выбранного раньше месяца или с января, — а месяц
      // человек меняет на шаге «Точка отсчёта» или перетаскиванием клетки.
      await _load(emit, preferredAnchor ?? _defaultAnchor);
    } on ScheduleProgramMissingException {
      // Программы у модели нет — раскладывать нечего, но мастер всё равно
      // открыт: правка программы живёт в нём же, и отправлять человека с
      // плашкой «ошибка» некуда.
      emit(ScheduleWizardLoaded(
        data: null,
        anchorMonth: preferredAnchor ?? _defaultAnchor,
      ));
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

  /// Человек сохранил программу в окне правки.
  ///
  /// Сначала `PUT`, потом заготовка заново: год раскладывает сервер, и после
  /// правки цикла показывать прежние клетки значило бы врать.
  Future<void> _onProgramSaved(
    WizardProgramSaved event,
    Emitter<ScheduleWizardState> emit,
  ) async {
    final ScheduleWizardState current = state;
    if (current is! ScheduleWizardLoaded) return;

    emit(current.copyWith(isReloading: true));
    try {
      await _programs.save(event.program);
    } on SchedulesException catch (error) {
      emit(current.copyWith(error: error.message));
      return;
    } catch (_) {
      emit(current.copyWith(error: 'Не удалось сохранить программу'));
      return;
    }

    await _openPreview(emit, preferredAnchor: current.anchorMonth);
  }

  Future<void> _onApproved(
    WizardApproved event,
    Emitter<ScheduleWizardState> emit,
  ) async {
    final ScheduleWizardState current = state;
    if (current is! ScheduleWizardLoaded) return;
    // Второе нажатие, пока идёт первое, отбиваем здесь, а не только серым
    // видом кнопки: ручка идемпотентна, но лишний запрос всё равно незачем.
    if (current.isApproving) return;

    emit(current.copyWith(isApproving: true));
    try {
      // Месяц берём тот, что показан в предпросмотре: человек утверждал
      // именно эту ленту.
      await _repository.generate(
        objectId,
        year,
        anchorMonth: current.anchorMonth,
      );
      emit(const ScheduleWizardApproved());
    } on SchedulesException catch (error) {
      emit(current.copyWith(error: error.message));
    } catch (_) {
      emit(current.copyWith(error: 'Не удалось создать график'));
    }
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
