import 'package:els/mechanic/data/defect_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// Привязка дефекта: что уезжает в теле `POST /defective-act/`.
///
/// Сервер принимает ровно одну ссылку и отвечает 422, если их несколько и
/// объекты у них разные (`CrudDefectiveAct._resolve_object`). Здесь
/// проверяется, что собрать такое тело нечем.
void main() {
  test('дефект по ТО уезжает одним act_fact_id', () {
    expect(const DefectLink.act(12).toBody(), <String, dynamic>{
      'act_fact_id': 12,
    });
  });

  test('пункт чек-листа добавляет номер, не заменяя акт', () {
    expect(const DefectLink.act(12, stepId: 3).toBody(), <String, dynamic>{
      'act_fact_id': 12,
      'checklist_step_id': 3,
    });
  });

  test('заявка и объект уезжают своей единственной ссылкой', () {
    expect(const DefectLink.order(7).toBody(), <String, dynamic>{'order_id': 7});
    expect(
      const DefectLink.object(41).toBody(),
      <String, dynamic>{'object_id': 41},
    );
  });

  test('в теле всегда ровно одна привязка', () {
    const List<DefectLink> links = <DefectLink>[
      DefectLink.act(12),
      DefectLink.act(12, stepId: 3),
      DefectLink.order(7),
      DefectLink.object(41),
    ];

    for (final DefectLink link in links) {
      final Iterable<String> bindings = link.toBody().keys.where(
            (String key) => key != 'checklist_step_id',
          );
      expect(bindings.length, 1, reason: 'привязок в теле: $bindings');
    }
  });

  test('подпись очереди называет место, а не номер акта', () {
    expect(const DefectLink.act(12, stepId: 3).label, 'по ТО №12');
    expect(const DefectLink.order(7).label, 'по заявке №7');
    expect(const DefectLink.object(41).label, 'по объекту №41');
  });
}
