/// Модель лифта из справочника (`factories_models`).
class TemplateModel {
  const TemplateModel({required this.id, required this.name});

  final int id;
  final String name;
}

/// Вид ТО глазами экрана шаблонов: у модели он либо с шаблоном, либо без.
///
/// Поля повторяют строку `acts_bases`: модель, вид ТО и плоский список
/// шагов. `templateId == null` — шаблона у этой пары ещё нет, и строка в
/// списке помечена «нет шаблона».
///
/// Удаление мягкое: вид с `deleted` остаётся в списке внизу, зачёркнутый,
/// и его можно вернуть. Акты, уже созданные по шаблону, живут со своим
/// снимком шагов и от удаления не страдают.
class TemplateTypeAct {
  const TemplateTypeAct({
    required this.typeActId,
    required this.typeActName,
    this.templateId,
    this.steps = const <String>[],
    this.deleted = false,
  });

  final int typeActId;
  final String typeActName;

  /// `acts_bases.id`; пусто — шаблон не заведён.
  final int? templateId;

  /// Шаги чек-листа по порядку. Подшагов нет — список плоский.
  final List<String> steps;

  /// Вид убран у модели: в график не встаёт, в списке — внизу и зачёркнут.
  final bool deleted;

  bool get hasTemplate => templateId != null;

  TemplateTypeAct copyWith({
    int? templateId,
    List<String>? steps,
    bool? deleted,
  }) {
    return TemplateTypeAct(
      typeActId: typeActId,
      typeActName: typeActName,
      templateId: templateId ?? this.templateId,
      steps: steps ?? this.steps,
      deleted: deleted ?? this.deleted,
    );
  }
}

/// Модель со всеми видами ТО справочника — с шаблоном и без.
class ModelTemplates {
  const ModelTemplates({required this.model, required this.types});

  final TemplateModel model;
  final List<TemplateTypeAct> types;

  /// Живые виды — без удалённых; счётчик «N из M» считается по ним.
  List<TemplateTypeAct> get active =>
      types.where((TemplateTypeAct t) => !t.deleted).toList();

  int get withTemplate =>
      active.where((TemplateTypeAct t) => t.hasTemplate).length;
}

/// Откуда копировать шаги: чужой шаблон, названный моделью и видом ТО.
class TemplateSource {
  const TemplateSource({
    required this.modelName,
    required this.typeActName,
    required this.steps,
  });

  final String modelName;
  final String typeActName;
  final List<String> steps;
}
