/// Кнопки карточки ТО: что можно нажать в каждом состоянии работы.
///
/// Проверяется правило, а не вёрстка. Ошибка здесь стоит дорого в обе
/// стороны: пропавшая пауза означает, что механик, уехавший на аварию,
/// оставит ТО «в работе» и прораб будет ждать несуществующую работу; лишняя
/// кнопка «Завершить работу» — что акт закроется с неотмеченными пунктами
/// раньше, чем механик их сделает.
library;

import 'package:els/mechanic/data/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('состояние работы по строке списка', () {
    Map<String, dynamic> row({
      int? startedAt,
      int? finishedAt,
      int statusId = OrderStatus.created,
    }) {
      return <String, dynamic>{
        'started_at': startedAt,
        'finished_at': finishedAt,
        'status_id': statusId,
      };
    }

    test('неначатое ТО не бывает ни на паузе, ни в проблеме', () {
      // У свежего акта статус «Создано», а у иного и вовсе чужой из
      // справочника: читать его как состояние работы значит придумать работу
      // там, где её не было.
      expect(maintenanceState(row()), MaintenanceState.notStarted);
      expect(
        maintenanceState(row(statusId: OrderStatus.problem)),
        MaintenanceState.notStarted,
      );
    });

    test('начатое без особого статуса — в работе', () {
      expect(
        maintenanceState(row(startedAt: 1000)),
        MaintenanceState.inWork,
      );
    });

    test('«Принято» при начатой работе означает паузу', () {
      expect(
        maintenanceState(row(startedAt: 1000, statusId: OrderStatus.accepted)),
        MaintenanceState.paused,
      );
    });

    test('закрытый акт остаётся сданным при любом статусе', () {
      expect(
        maintenanceState(
          row(startedAt: 1000, finishedAt: 2000, statusId: OrderStatus.problem),
        ),
        MaintenanceState.done,
      );
    });
  });

  group('кнопки карточки', () {
    test('до начала работы — только «Начать ТО»', () {
      final ActControls controls = actControls(
        MaintenanceState.notStarted,
        allDone: false,
      );

      expect(controls.mainLabel, 'Начать ТО');
      expect(controls.canPause, isFalse);
      expect(controls.canReportProblem, isFalse, reason: 'мешать ещё нечему');
    });

    test('в работе можно приостановиться и сообщить о проблеме', () {
      final ActControls controls = actControls(
        MaintenanceState.inWork,
        allDone: false,
      );

      expect(controls.mainLabel, 'Продолжить ТО');
      expect(controls.main, ActAction.open);
      expect(controls.canPause, isTrue);
      expect(controls.canReportProblem, isTrue);
    });

    test('все пункты отмечены — кнопка становится «Завершить работу»', () {
      final ActControls controls = actControls(
        MaintenanceState.inWork,
        allDone: true,
      );

      expect(controls.main, ActAction.close);
      expect(controls.mainLabel, 'Завершить работу');
      expect(controls.canPause, isTrue, reason: 'завершать не обязательно');
    });

    test('приостановленное возобновляется, второй раз не приостановить', () {
      final ActControls controls = actControls(
        MaintenanceState.paused,
        allDone: false,
      );

      expect(controls.main, ActAction.resume);
      expect(controls.mainLabel, 'Продолжить ТО');
      expect(controls.canPause, isFalse);
      expect(controls.canReportProblem, isTrue);
    });

    test('из проблемы выходят той же кнопкой «Продолжить ТО»', () {
      final ActControls controls = actControls(
        MaintenanceState.problem,
        allDone: false,
      );

      expect(controls.main, ActAction.resume);
      expect(controls.canPause, isFalse);
      expect(
        controls.canReportProblem,
        isFalse,
        reason: 'сообщать о проблеме, которая уже сообщена, незачем',
      );
    });

    test('в сданном акте нажимать нечего', () {
      final ActControls controls = actControls(
        MaintenanceState.done,
        allDone: true,
      );

      expect(controls.main, ActAction.none);
      expect(controls.canPause, isFalse);
      expect(controls.canReportProblem, isFalse);
    });
  });
}
