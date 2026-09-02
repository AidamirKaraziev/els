---
этап: 9 — чистка и переезд наброска программы в бой
статус: в работе
дата: 2026-09-03
план: els-vault/00-home/план - окно график объекта.md
---

# Передача: чистка сделана, переезд вёрстки — нет, дерево не собирается

**Ничего не закоммичено**, всё в рабочей копии; дерево не собирается.

## Сделано

- **Перетаскивание ТО убрано из ленты целиком**: `month_strip.dart`,
  `object_schedule_card.dart`, экран объекта, `ScheduleObjectCellMoved`,
  обработчик блока, `moveCell` в трёх файлах `object/repository/`. Тест
  переехал в `test/schedule/object_schedule_due_test.dart`: группа «срок
  ближайшего ТО» сохранена, группа переноса удалена со старым файлом.
- **Мастер двухшаговый**: `wizard_program_step.dart` удалён, `_titles`
  сокращён до «Точка отсчёта» + «Предпросмотр».
- **Заведена основа правки программы**: `wizard/models/maintenance_program.dart`
  и `wizard/repository/maintenance_program_repository.dart` с `api_`/`fixture_`
  реализациями поверх `by-model`, `.../suggestion/`, `/type-acts/`.
- **Блок мастера принимает программу**: событие `WizardProgramSaved` (PUT, за
  ним перезапрос preview), `ScheduleWizardLoaded.data` стал нullable,
  `ScheduleProgramMissingException` — 404 с кодом 143 больше не плашка ошибки.
- **`modelId`** добавлен в `ScheduleObjectCard` и разбирается из
  `factory_model_id.id` — по нему открывается окно правки программы.

## Не доделано

- **Дерево не компилируется.** `flutter analyze`: 14 ошибок в затронутом —
  `schedule_wizard_screen.dart` не разобран под nullable `data` и не передаёт
  `programRepository` в блок, два теста держатся за удалённое. (Общий счётчик
  репозитория 1382, база подрядчика не сверялась.)
- **Вёрстка предпросмотра не переехала**: строка программы, перетаскивание
  клеток (сдвиг цикла → `WizardAnchorChanged`), плашки «программы нет» и
  `_KnownAnchorNote` из удалённого шага — всё ещё только в наброске.
- **Окно правки программы в бою не написано** (`wizard_program_dialog.dart`).
- **Набросок `lib/dev/draft/` и точка 5603 на месте** — удаляются последними.
- `flutter test`, `make lint`, `make test` не гонялись: смысла до сборки нет.
- В базе у `planned_to` 87 (объект 25, 2027) освобождён декабрь: вернуть
  `december_to_id = 320`.

## Следующий этап

**Цель.** Дописать переезд: предпросмотр со строкой программы и окном её
правки, работающий против боевых ручек.

**Готово, когда.** `flutter analyze` без новых ошибок, `flutter test`,
`make lint`, `make test` чисты; на живой точке 5602 правка программы
сохраняется и клетки года перерисовываются.

## Первые шаги

1. Переписать `object/wizard/widgets/wizard_preview_step.dart` по
   `lib/dev/draft/draft_preview_page.dart`: `_ProgramRow`, `_DraggableCell`
   (`anchor = (toMonth - position + 12) % 12 + 1` → `WizardAnchorChanged`),
   `_NoProgramNote`, плашка про уже известный цикл. Данные — `ScheduleWizardData?`.
2. Перенести `lib/dev/draft/draft_program_dialog.dart` в
   `object/wizard/widgets/wizard_program_dialog.dart` на `MaintenanceProgram`
   и `TypeAct`; окно само грузит `program`/`suggestion`/`typeActs`. Вид ТО без
   `id` (заведён локально — ручки на создание нет) гасит «Сохранить».
3. Разобрать `schedule_wizard_screen.dart` под nullable `data` и прокинуть
   `programRepository` с `modelId`: мастеру их даёт экран объекта из
   `state.card.modelId`; параметр придётся добавить в `ScheduleObjectScreen`
   и в пять мест вызова в тестах и `lib/dev/`.
4. Починить `object_schedule_wizard_test.dart` (два шага) и
   `schedule_wizard_bloc_test.dart` (`programRepository`, nullable `data`).

## Не трогать

- `schedule_page.dart`, `schedule_page_foreman.dart` и прочие экраны
  подрядчика — они в проде.
- Бэкенд целиком: ручки готовы, ручку на создание вида ТО не заводим.

## Ссылки

- `frontend/lib/dev/draft/` — утверждённый набросок, отсюда переезжает вёрстка.
- `~/.claude/plans/sharded-soaring-pizza.md` — план этапа, части B–D не сделаны.
- `.claude/launch.json` — точки 5602 (живая) и 5603 (набросок, удалить).
