import '../../../repository/schedules_repository.dart';
import '../fixture_schedule_wizard_data.dart';
import '../models/schedule_wizard_data.dart';
import 'schedule_wizard_repository.dart';

/// Мастер без сети: тот же интерфейс поверх готовых раскладов.
///
/// Оборачивает существующий [buildWizardFixture], а не повторяет его: на нём
/// держатся dev-точка входа и тесты вида, и второй такой сборки быть не
/// должно — разойдутся, и на показе будет один график, а в тестах другой.
class FixtureScheduleWizardRepository implements ScheduleWizardRepository {
  const FixtureScheduleWizardRepository({
    this.fixture = WizardFixture.ok,
    this.withKnownAnchor = false,
    this.withProgram = true,
    this.delay = const Duration(milliseconds: 200),
  });

  final WizardFixture fixture;

  /// Есть ли у объекта график за прошлый год: есть — шаг «Точка отсчёта»
  /// пропускается, нет — первый же запрос требует месяц.
  final bool withKnownAnchor;

  /// Заведена ли у модели программа. Нет — предпросмотр не строится вовсе,
  /// ровно как отвечает сервер: 404 и предложение завести программу.
  final bool withProgram;

  /// Задержка ответа. Без неё загрузку не видно вовсе, и проверить, что экран
  /// её показывает, можно было бы только на живом сервере.
  final Duration delay;

  @override
  Future<ScheduleWizardData> preview(
    int objectId,
    int year, {
    int? anchorMonth,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    if (!withProgram) {
      throw const ScheduleProgramMissingException(
        'У модели этого объекта нет программы обслуживания!',
      );
    }

    // Прошлого года нет и месяц не назвали — ровно тот случай, ради которого
    // существует шаг «Точка отсчёта». Фикстура повторяет ответ сервера, иначе
    // эту ветку было бы негде увидеть без базы.
    if (!withKnownAnchor && anchorMonth == null) {
      throw const ScheduleAnchorRequiredException(
        'Укажите месяц, с которого начинается цикл: графика за прошлый год нет',
      );
    }

    return buildWizardFixture(
      fixture,
      year: year,
      withKnownAnchor: withKnownAnchor,
      anchorMonth: anchorMonth ?? _fixtureAnchor,
    );
  }

  @override
  Future<void> generate(
    int objectId,
    int year, {
    required int anchorMonth,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    // Живой бэкенд на такой расклад отвечает 422 и график не создаёт вовсе.
    // Повторяем отказ здесь, иначе на фикстуре «Утвердить» заканчивалось бы
    // успехом там, где на сервере ничего не создастся.
    if (fixture == WizardFixture.withMissingTemplate) {
      throw const SchedulesException(
        'У модели нет шаблонов чек-листа на отмеченные виды ТО!',
      );
    }
  }

  /// Якорь, который «восстановился по прошлому году». Тот же, что зашит в
  /// фикстуре: март — чтобы позиция цикла и месяц календаря заведомо не
  /// совпадали.
  static const int _fixtureAnchor = 3;
}
