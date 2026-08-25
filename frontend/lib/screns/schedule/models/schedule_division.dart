import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Участок в первом окне «Графиков» (кадр Figma `3:339`).
///
/// Экран отвечает на один вопрос: где график проваливается. Поэтому в строке
/// только номер, название, прораб и процент — ни объектов, ни лент.
class ScheduleDivision {
  const ScheduleDivision({
    required this.divisionId,
    required this.number,
    required this.title,
    required this.plannedCount,
    required this.completedCount,
    required this.completionPercent,
    this.foreman,
  });

  final int divisionId;

  /// Номер в кружке. Порядковый в выдаче, а не id: id — внутреннее число,
  /// человеку оно ничего не говорит.
  final int number;

  final String title;
  final String? foreman;

  final int plannedCount;
  final int completedCount;
  final double completionPercent;

  String get titleLabel => title.trim().isEmpty ? 'Без участка' : title.trim();
  String get foremanLabel => foreman?.trim().isNotEmpty == true
      ? foreman!.trim()
      : 'Прораб не назначен';

  /// Пороги те же, что у карточки «Выполнение графика» на главной
  /// (`home/schedule_execution/models/schedule_execution_report.dart`).
  /// Два разных набора порогов в одном приложении означали бы, что участок
  /// зелёный на главной и жёлтый в графиках.
  Color get color {
    if (completionPercent >= kGoodPercent) return ColorApp.myColorGreen;
    if (completionPercent >= kFairPercent) return ColorApp.myColorYellow;
    return ColorApp.myColorRed;
  }

  static const double kGoodPercent = 90;
  static const double kFairPercent = 70;

  /// График на участке не заводили — процент считать не от чего.
  bool get hasNoPlan => plannedCount == 0;

  factory ScheduleDivision.fromJson(Map<String, dynamic> json, int number) {
    return ScheduleDivision(
      divisionId: _asInt(json['division_id']) ?? 0,
      number: number,
      title: _asString(json['division']) ?? '',
      foreman: _asString(json['foreman']),
      plannedCount: _asInt(json['planned_count']) ?? 0,
      completedCount: _asInt(json['completed_count']) ?? 0,
      completionPercent: _asDouble(json['completion_percent']) ?? 0,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
