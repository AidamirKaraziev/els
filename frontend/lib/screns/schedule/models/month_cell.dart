import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Состояние планового ТО за один месяц.
///
/// Ровно тот же набор, что считает бэкенд в отчётах — `MaintenanceStatus` в
/// `backend/src/schemas/reports.py`. Второй классификации заводить нельзя:
/// лента графиков и отчёты обязаны называть одно и то же одинаково, иначе
/// прораб видит в графике зелёный месяц, а в отчёте — просрочку.
///
/// [pending] и [overdue] различаются только тем, кончился ли плановый месяц.
/// Незакрытое ТО за текущий месяц — работа впереди, за прошедший — долг.
enum MonthStatus {
  /// ТО на этот месяц вообще не назначено. Не ошибка и не долг: в графике
  /// объекта эта клетка пустая.
  none,

  /// Назначено, срок ещё не вышел.
  pending,

  /// Выполнено в свой месяц.
  done,

  /// Выполнено, но позже своего месяца.
  late,

  /// Не выполнено, месяц кончился.
  overdue,
}

/// Как разобрать значение, пришедшее с сервера.
///
/// Незнакомое слово превращается в [MonthStatus.none], а не роняет экран:
/// список графиков — не то место, где новый статус на бэке должен показать
/// красный экран вместо работы.
MonthStatus monthStatusFromJson(dynamic value) {
  switch (value) {
    case 'done':
      return MonthStatus.done;
    case 'late':
      return MonthStatus.late;
    case 'overdue':
      return MonthStatus.overdue;
    case 'pending':
      return MonthStatus.pending;
    default:
      return MonthStatus.none;
  }
}

extension MonthStatusView on MonthStatus {
  /// Заливка клетки. Цвета только из палитры проекта — своих не заводим.
  ///
  /// У [MonthStatus.none] заливки нет: пустой месяц не должен весить столько
  /// же, сколько назначенное и несделанное ТО. Он рисуется одним контуром.
  Color? get fill {
    switch (this) {
      case MonthStatus.done:
        return ColorApp.myColorGreen;
      case MonthStatus.late:
        return ColorApp.myColorYellow;
      case MonthStatus.overdue:
        return ColorApp.myColorRed;
      case MonthStatus.pending:
        return ColorApp.myColorGrayText;
      case MonthStatus.none:
        return null;
    }
  }

  /// Цвет текста внутри клетки.
  ///
  /// На жёлтом белый текст не читается — там чёрный, на остальных заливках
  /// белый.
  Color get foreground {
    switch (this) {
      case MonthStatus.late:
        return ColorApp.myColorBlack;
      case MonthStatus.none:
        return ColorApp.myColorGrayText;
      default:
        return ColorApp.myColorWhite;
    }
  }

  Color get border {
    return fill ?? ColorApp.myColorGrayBorder;
  }

  /// Словами — для тултипа и для чтения с экрана.
  String get title {
    switch (this) {
      case MonthStatus.done:
        return 'выполнено';
      case MonthStatus.late:
        return 'выполнено не вовремя';
      case MonthStatus.overdue:
        return 'не выполнено, срок вышел';
      case MonthStatus.pending:
        return 'назначено';
      case MonthStatus.none:
        return 'ТО не назначено';
    }
  }
}

/// Клетка месяца в годовой ленте графика.
class MonthCell {
  const MonthCell({
    required this.month,
    required this.status,
    this.toName,
    this.actId,
  });

  /// 1..12.
  final int month;

  final MonthStatus status;

  /// «ТО 1», «ТО 6» — вид работы. У [MonthStatus.none] пусто.
  final String? toName;

  /// Работа, которая стоит за клеткой (`act_fact.id`). Именно её открывает
  /// клик. У незанятого месяца её нет.
  final int? actId;

  /// Пустой месяц никуда не ведёт: открывать нечего.
  bool get isTappable => actId != null && status != MonthStatus.none;

  /// Короткая подпись для узкого окна: двенадцать «ТО 12» рядом с четырьмя
  /// колонками не помещаются даже на 1280 px.
  String get shortLabel => '$month';

  String get label => toName ?? '';

  factory MonthCell.empty(int month) =>
      MonthCell(month: month, status: MonthStatus.none);

  factory MonthCell.fromJson(Map<String, dynamic> json) {
    return MonthCell(
      month: _asInt(json['month']) ?? 0,
      status: monthStatusFromJson(json['status']),
      toName: _asString(json['to_name']),
      actId: _asInt(json['act_id']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
