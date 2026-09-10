import 'object_works.dart';

/// Дефектный акт в списке за период по всему отбору — то, что открывается с
/// плитки сводки.
///
/// Это [DefectItem] плюс объект: в шторке объекта объект и так известен, а в
/// общем списке каждая строка обязана сказать, о каком доме речь.
/// Форма строки ждёт ручку на сервере (S03); на фикстуре собирается из тех
/// же полей, что уже есть у `defect_details` в файле выгрузки.
class ReportDefectRow {
  const ReportDefectRow({
    required this.objectId,
    required this.objectName,
    required this.address,
    required this.defect,
  });

  factory ReportDefectRow.fromJson(Map<String, dynamic> json) =>
      ReportDefectRow(
        objectId: json['object_id'] is num ? (json['object_id'] as num).toInt() : 0,
        objectName: _string(json['object_name']),
        address: _string(json['address']),
        defect: DefectItem.fromJson(json),
      );

  final int objectId;
  final String? objectName;
  final String? address;
  final DefectItem defect;

  String get objectLabel => objectName ?? 'Объект $objectId';
  String get addressLabel => address ?? '—';

  static String? _string(dynamic value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
