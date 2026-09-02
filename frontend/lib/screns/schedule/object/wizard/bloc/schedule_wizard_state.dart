part of 'schedule_wizard_bloc.dart';

@immutable
abstract class ScheduleWizardState {
  const ScheduleWizardState();
}

class ScheduleWizardInitial extends ScheduleWizardState {
  const ScheduleWizardInitial();
}

class ScheduleWizardLoading extends ScheduleWizardState {
  const ScheduleWizardLoading();
}

/// Заготовка построена: три шага мастера есть чем наполнить.
class ScheduleWizardLoaded extends ScheduleWizardState {
  const ScheduleWizardLoaded({
    required this.data,
    required this.anchorMonth,
    this.isReloading = false,
    this.error,
  });

  final ScheduleWizardData data;

  /// Месяц, на который приходится первая позиция программы: восстановленный
  /// сервером по прошлому году или названный человеком.
  final int anchorMonth;

  /// Идёт перезапрос после смены месяца. Прежняя заготовка на это время
  /// остаётся на экране — человек смотрит, что изменится в ленте.
  final bool isReloading;

  /// Что пошло не так с перезапросом. Живёт рядом с заготовкой, а не
  /// отдельным состоянием: прежнюю ленту терять из-за одной неудачной смены
  /// месяца незачем.
  final String? error;

  /// Шаг «Точка отсчёта» отпадает, когда цикл продолжается с прошлого года.
  bool get hasAnchorStep => !data.hasPreviousYear;

  /// [error] задаётся только явно: `null` в аргументе означает «убрать прошлую
  /// ошибку», а не «оставить как было». Иначе текст неудачи висел бы на экране
  /// и после удачного повтора.
  ScheduleWizardLoaded copyWith({
    ScheduleWizardData? data,
    int? anchorMonth,
    bool? isReloading,
    String? error,
  }) {
    return ScheduleWizardLoaded(
      data: data ?? this.data,
      anchorMonth: anchorMonth ?? this.anchorMonth,
      isReloading: isReloading ?? false,
      error: error,
    );
  }
}

/// Заготовку построить не удалось.
///
/// Текст показываем прямо человеку, поэтому он приходит уже готовым из
/// репозитория — без кодов ответа и стектрейсов.
class ScheduleWizardFailure extends ScheduleWizardState {
  const ScheduleWizardFailure(this.message);

  final String message;
}
