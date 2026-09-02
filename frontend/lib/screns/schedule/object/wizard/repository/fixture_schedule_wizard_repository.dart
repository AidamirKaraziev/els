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
    this.withPreviousYear = false,
    this.delay = const Duration(milliseconds: 200),
  });

  final WizardFixture fixture;

  /// Есть ли у объекта график за прошлый год: есть — шаг «Точка отсчёта»
  /// пропускается, нет — первый же запрос требует месяц.
  final bool withPreviousYear;

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

    // Прошлого года нет и месяц не назвали — ровно тот случай, ради которого
    // существует шаг «Точка отсчёта». Фикстура повторяет ответ сервера, иначе
    // эту ветку было бы негде увидеть без базы.
    if (!withPreviousYear && anchorMonth == null) {
      throw const ScheduleAnchorRequiredException(
        'Укажите месяц, с которого начинается цикл: графика за прошлый год нет',
      );
    }

    return buildWizardFixture(
      fixture,
      year: year,
      withPreviousYear: withPreviousYear,
      anchorMonth: anchorMonth ?? _fixtureAnchor,
    );
  }

  /// Якорь, который «восстановился по прошлому году». Тот же, что зашит в
  /// фикстуре: март — чтобы позиция цикла и месяц календаря заведомо не
  /// совпадали.
  static const int _fixtureAnchor = 3;
}
