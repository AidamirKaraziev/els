part of 'schedule_wizard_bloc.dart';

@immutable
abstract class ScheduleWizardEvent {
  const ScheduleWizardEvent();
}

/// Построить заготовку графика.
///
/// Годится и первому открытию мастера, и повтору после ошибки: запрос один и
/// тот же, и разводить их по двум событиям значило бы дважды писать один путь.
class WizardOpened extends ScheduleWizardEvent {
  const WizardOpened();
}

/// Человек назвал месяц начала цикла на шаге «Точка отсчёта».
///
/// Заготовка перезапрашивается: раскладку по месяцам считает сервер, и
/// провернуть её на клиенте — значит завести вторую арифметику цикла.
class WizardAnchorChanged extends ScheduleWizardEvent {
  const WizardAnchorChanged(this.month);

  /// 1..12, месяц календаря.
  final int month;
}

/// Человек нажал «Утвердить»: расставить год в базе.
///
/// Месяца в событии нет намеренно — блок берёт тот, что сейчас показан в
/// предпросмотре. Иначе на кнопке и в ленте могли бы оказаться разные якоря.
class WizardApproved extends ScheduleWizardEvent {
  const WizardApproved();
}
