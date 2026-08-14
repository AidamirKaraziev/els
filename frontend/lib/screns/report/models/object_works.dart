import 'works_report.dart';

/// Модели ответа `GET /api/v1/reports/object/{id}/works` — уровни 2 и 3.
///
/// Три списка, а не один: у ТО и у заявки нет общего набора полей, и сведение
/// их в одну плоскую запись означало бы половину полей пустыми в каждой
/// строке. Ленту по датам собирает экран — слиянием.

int _int(dynamic value) => value is num ? value.toInt() : 0;

double? _double(dynamic value) => value is num ? value.toDouble() : null;

String? _string(dynamic value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateTime(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Вид работы. Совпадает с `WorkKind` на бэкенде.
enum WorkKind { maintenance, breakdown, clientRequest, request, defect }

WorkKind _kindFrom(dynamic raw) {
  switch (raw) {
    case 'breakdown':
      return WorkKind.breakdown;
    case 'client_request':
      return WorkKind.clientRequest;
    case 'request':
      return WorkKind.request;
    case 'defect':
      return WorkKind.defect;
    default:
      return WorkKind.maintenance;
  }
}

String workKindLabel(WorkKind kind) {
  switch (kind) {
    case WorkKind.maintenance:
      return 'Плановое ТО';
    case WorkKind.breakdown:
      return 'Аварийный выезд';
    case WorkKind.clientRequest:
      return 'Заявка заказчика';
    case WorkKind.request:
      return 'Прочая работа';
    case WorkKind.defect:
      return 'Дефектная ведомость';
  }
}

/// Пункт чек-листа акта ТО.
class WorkStep {
  const WorkStep({required this.title, required this.done});

  factory WorkStep.fromJson(Map<String, dynamic> json) => WorkStep(
        title: _string(json['title']) ?? '—',
        done: json['done'] == true,
      );

  final String title;
  final bool done;
}

/// Дефектная ведомость, составленная по итогам ТО.
class DefectItem {
  const DefectItem({
    required this.defectId,
    required this.title,
    required this.description,
    required this.month,
    required this.status,
    required this.responsible,
    required this.createdAt,
    required this.photoCount,
  });

  factory DefectItem.fromJson(Map<String, dynamic> json) => DefectItem(
        defectId: _int(json['defect_id']),
        title: _string(json['title']) ?? 'Без названия',
        description: _string(json['description']),
        month: _int(json['month']),
        status: _string(json['status']),
        responsible: _string(json['responsible']),
        createdAt: _dateTime(json['created_at']),
        photoCount: _int(json['photo_count']),
      );

  final int defectId;
  final String title;
  final String? description;
  final int month;
  final String? status;
  final String? responsible;
  final DateTime? createdAt;
  final int photoCount;
}

/// Плановое ТО за месяц со всем, что в него вошло.
class MaintenanceWork {
  const MaintenanceWork({
    required this.actId,
    required this.year,
    required this.month,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.daysLate,
    required this.foreman,
    required this.mechanic,
    required this.steps,
    required this.defects,
  });

  factory MaintenanceWork.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSteps =
        json['steps'] is List ? json['steps'] as List<dynamic> : <dynamic>[];
    final List<dynamic> rawDefects =
        json['defects'] is List ? json['defects'] as List<dynamic> : <dynamic>[];

    return MaintenanceWork(
      actId: _int(json['act_id']),
      year: _int(json['year']),
      month: _int(json['month']),
      status: maintenanceStatusFrom(json['status']),
      startedAt: _dateTime(json['started_at']),
      finishedAt: _dateTime(json['finished_at']),
      daysLate: json['days_late'] is num
          ? (json['days_late'] as num).toInt()
          : null,
      foreman: _string(json['foreman']),
      mechanic: _string(json['mechanic']),
      steps: rawSteps
          .whereType<Map>()
          .map((Map raw) => WorkStep.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
      defects: rawDefects
          .whereType<Map>()
          .map((Map raw) => DefectItem.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  final int actId;
  final int year;
  final int month;
  final MaintenanceStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// На сколько дней позже конца планового месяца закрыт акт.
  final int? daysLate;

  final String? foreman;
  final String? mechanic;
  final List<WorkStep> steps;
  final List<DefectItem> defects;

  int get doneSteps => steps.where((WorkStep step) => step.done).length;

  /// Пустой чек-лист означает «механик его не заполнял», а не «работ не
  /// было». Разница существенная, и экран обязан называть её словами.
  bool get hasChecklist => steps.isNotEmpty;

  /// По какой дате ставить работу в ленту. Закрытый акт — по дате закрытия,
  /// незакрытый — по первому числу планового месяца: иначе он провалился бы
  /// в конец списка и потерялся.
  DateTime get sortDate => finishedAt ?? DateTime(year, month, 1);
}

/// Заявка: аварийный выезд, задача от заказчика или прочая работа.
class RequestWork {
  const RequestWork({
    required this.kind,
    required this.orderId,
    required this.createdAt,
    required this.acceptedAt,
    required this.doneAt,
    required this.reactionHours,
    required this.category,
    required this.categoryCode,
    required this.reason,
    required this.taskText,
    required this.commentary,
    required this.status,
    required this.creator,
    required this.executor,
    required this.photoCount,
  });

  factory RequestWork.fromJson(Map<String, dynamic> json) => RequestWork(
        kind: _kindFrom(json['kind']),
        orderId: _int(json['order_id']),
        createdAt: _dateTime(json['created_at']),
        acceptedAt: _dateTime(json['accepted_at']),
        doneAt: _dateTime(json['done_at']),
        reactionHours: _double(json['reaction_hours']),
        category: _string(json['category']),
        categoryCode: _string(json['category_code']),
        reason: _string(json['reason']),
        taskText: _string(json['task_text']),
        commentary: _string(json['commentary']),
        status: _string(json['status']),
        creator: _string(json['creator']),
        executor: _string(json['executor']),
        photoCount: _int(json['photo_count']),
      );

  final WorkKind kind;
  final int orderId;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? doneAt;
  final double? reactionHours;
  final String? category;
  final String? categoryCode;
  final String? reason;
  final String? taskText;
  final String? commentary;
  final String? status;
  final String? creator;
  final String? executor;
  final int photoCount;

  /// Чем подписать заявку. Текст заявки бывает пустым — тогда категория.
  String get title => taskText ?? category ?? 'Заявка №$orderId';

  DateTime get sortDate => createdAt ?? DateTime(1970);
}

/// Все работы на одном объекте за период.
class ObjectWorksReport {
  const ObjectWorksReport({
    required this.object,
    required this.period,
    required this.maintenance,
    required this.requests,
    required this.defects,
  });

  factory ObjectWorksReport.fromJson(Map<String, dynamic> json) {
    List<dynamic> listOf(String key) =>
        json[key] is List ? json[key] as List<dynamic> : <dynamic>[];

    return ObjectWorksReport(
      object: ReportObjectRow.fromJson(
        (json['object'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      period: ReportPeriod.fromJson(
        (json['period'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      maintenance: listOf('maintenance')
          .whereType<Map>()
          .map((Map raw) =>
              MaintenanceWork.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
      requests: listOf('requests')
          .whereType<Map>()
          .map((Map raw) => RequestWork.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
      defects: listOf('defects')
          .whereType<Map>()
          .map((Map raw) => DefectItem.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  final ReportObjectRow object;
  final ReportPeriod period;
  final List<MaintenanceWork> maintenance;
  final List<RequestWork> requests;
  final List<DefectItem> defects;

  bool get isEmpty => maintenance.isEmpty && requests.isEmpty;
}
