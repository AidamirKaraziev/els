import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/schedules_repository.dart';
import '../models/schedule_object_card.dart';
import '../repository/schedule_object_repository.dart';

part 'schedule_object_event.dart';
part 'schedule_object_state.dart';

/// Карточка объекта на экране графика.
///
/// Репозиторий обязателен: подставлять сюда сетевой по умолчанию нечего —
/// в `S2.1` сети ещё нет, и молчаливая замена фикстуры на несуществующую
/// ручку выглядела бы как пустой экран без единой ошибки.
class ScheduleObjectBloc extends Bloc<ScheduleObjectEvent, ScheduleObjectState> {
  ScheduleObjectBloc({
    required ScheduleObjectRepository repository,
    required this.objectId,
  })  : _repository = repository,
        super(const ScheduleObjectInitial()) {
    on<ScheduleObjectRequested>(_onRequested);
  }

  final ScheduleObjectRepository _repository;
  final int objectId;

  Future<void> _onRequested(
    ScheduleObjectRequested event,
    Emitter<ScheduleObjectState> emit,
  ) async {
    emit(const ScheduleObjectLoading());
    try {
      final ScheduleObjectCard card = await _repository.fetchCard(objectId);
      emit(ScheduleObjectLoaded(card));
    } on SchedulesException catch (error) {
      emit(ScheduleObjectFailure(error.message));
    } catch (_) {
      emit(const ScheduleObjectFailure('Не удалось загрузить объект'));
    }
  }
}
