import '../models/checklist_template.dart';

/// Откуда экран «Шаблоны ТО» берёт модели, виды и шаги.
///
/// Пока одна реализация — фикстура: экран рисуется до ручек, а сетевая
/// версия поверх `/acts-bases/` появится, когда макет утверждён (S04).
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
  Future<void> removeTypeAct({required int modelId, required int typeActId});

  /// Вернуть убранный вид ТО у модели вместе с его шаблоном.
  Future<void> restoreTypeAct({required int modelId, required int typeActId});

  /// Заведённые шаблоны, откуда можно скопировать шаги. Свой собственный
  /// (та же модель и вид) экран из списка убирает сам.
  Future<List<TemplateSource>> sources();
}
