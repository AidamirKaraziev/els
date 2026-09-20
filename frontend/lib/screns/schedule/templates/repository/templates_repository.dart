import '../../repository/schedules_repository.dart';
import '../models/checklist_template.dart';

/// Откуда экран «Шаблоны ТО» берёт модели, виды и шаги.
///
/// Две реализации: фикстура для превью и тестов вёрстки и сетевая поверх
/// `/acts-bases/` — `api_templates_repository.dart`.
abstract class TemplatesRepository {
  /// Все модели справочника, у каждой — все виды ТО, с шаблоном и без.
  Future<List<ModelTemplates>> loadAll();

  /// Записать шаги шаблона пары модель × вид ТО. Шаблона не было — создать.
  Future<void> save({
    required int modelId,
    required int typeActId,
    required List<String> steps,
  });

  /// Завести вид ТО у одной модели — без шаблона. У других моделей он не
  /// появляется: набор видов у каждой свой.
  Future<void> addTypeAct({required int modelId, required String name});

  /// Убрать вид ТО у модели — мягко: строка остаётся внизу списка
  /// зачёркнутой, шаблон не стирается, вид можно вернуть. Акты, созданные
  /// по шаблону раньше, не меняются: у каждого свой снимок шагов.
  ///
  /// По шаблону стоят ещё не начатые ТО — сервер отказывает, и метод бросает
  /// [TemplateInUseException]; экран спрашивает человека и повторяет с
  /// `force: true`.
  Future<void> removeTypeAct({
    required int modelId,
    required int typeActId,
    bool force = false,
  });

  /// Вернуть убранный вид ТО у модели вместе с его шаблоном.
  Future<void> restoreTypeAct({required int modelId, required int typeActId});

  /// Заведённые шаблоны, откуда можно скопировать шаги. Свой собственный
  /// (та же модель и вид) экран из списка убирает сам.
  Future<List<TemplateSource>> sources();
}

/// Вид ТО не убран: по шаблону стоят ещё не начатые ТО (код 1213).
///
/// Текст — с сервера, там названо число ТО. Отдельный класс, а не текст
/// в плашке, потому что экран на эту ошибку отвечает вопросом, а не
/// сообщением: убрать всё равно или оставить.
class TemplateInUseException extends SchedulesException {
  const TemplateInUseException(String message) : super(message);
}
