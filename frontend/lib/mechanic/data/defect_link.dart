/// К чему привязан дефект: одна ссылка из четырёх.
///
/// Дефект механик находит в четырёх разных местах — в работе по ТО, на
/// конкретном пункте её чек-листа, в аварийной заявке и просто на объекте, —
/// и `POST /defective-act/` принимает любую из привязок
/// (`backend/src/schemas/defective_act.py`). Но **только одну**: если
/// прислать две и объекты у них разойдутся, сервер отвечает 422, а не
/// выбирает главную (`CrudDefectiveAct._resolve_object`).
///
/// Поэтому привязка здесь — значение с именованными конструкторами, а не
/// четыре необязательных `int?` в подписи отправки. Такую пару, которой
/// сервер не обрадуется, просто некому собрать.
library;

class DefectLink {
  /// Дефект нашёлся в работе по ТО. `stepId` — если на конкретном пункте
  /// чек-листа.
  const DefectLink.act(int actId, {int? stepId})
      : _actId = actId,
        _stepId = stepId,
        _orderId = null,
        _objectId = null;

  /// Дефект нашёлся по аварийной заявке.
  const DefectLink.order(int orderId)
      : _actId = null,
        _stepId = null,
        _orderId = orderId,
        _objectId = null;

  /// Дефект нашёлся на объекте, вне работы и заявки.
  const DefectLink.object(int objectId)
      : _actId = null,
        _stepId = null,
        _orderId = null,
        _objectId = objectId;

  final int? _actId;

  /// Номер пункта внутри акта, а не внешний ключ шага регламента: тем же
  /// числом адресуется снимок пункта (`/act-fact/{id}/step/{step_id}/photo/`).
  final int? _stepId;

  final int? _orderId;
  final int? _objectId;

  /// Привязка в теле запроса. `checklist_step_id` уходит только вместе с
  /// `act_fact_id`: сам по себе он ни на что не указывает.
  Map<String, dynamic> toBody() {
    if (_actId != null) {
      return <String, dynamic>{
        'act_fact_id': _actId,
        if (_stepId != null) 'checklist_step_id': _stepId,
      };
    }
    if (_orderId != null) return <String, dynamic>{'order_id': _orderId};
    return <String, dynamic>{'object_id': _objectId};
  }

  /// Как привязка называется в очереди — механик видит эту строку в списке
  /// неотправленного, и «Дефект по ТО №12» ему говорит больше, чем номер
  /// акта сам по себе. Номер пункта в подпись не берём: в очереди он
  /// ничего не объясняет.
  String get label {
    if (_actId != null) return 'по ТО №$_actId';
    if (_orderId != null) return 'по заявке №$_orderId';
    return 'по объекту №$_objectId';
  }
}
