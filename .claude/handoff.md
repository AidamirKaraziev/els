---
этап: E01·S01 — макет раздела «Графики» крупнее, значок актов в строке
статус: закрыт
дата: 2026-09-10
план: .claude/plan/E01-grafiki.md
---

# Передача: макет S01 утверждён, дальше — число из API и тап (S02)

## Сделано и проверено

- Ряд раздела «Графики» крупнее: высота 112, кегль 14/12, лента с подписями
  месяцев на ширине ≥ 1000 (`frontend/lib/screns/schedule/widgets/schedule_row_tile.dart`).
- `DefectsBadge` стоит своей колонкой `_BadgeSlot` (44 px) сразу после
  названия — значки в одной вертикали; ноль — серый без цифры;
  `defectsCount == null` — пустая ячейка. Утверждено пользователем по скринам
  1440 / 1100 / 390.
- `ScheduleRow.defectsCount` читается из `defects_count` (`models/schedule_row.dart`).
- Фикстура переехала: `frontend/lib/screns/schedule/repository/fixture_schedules_repository.dart`,
  первый объект «создаю тест» с 5 актами; 9 тестов импортируют её из `lib`.
- Превью: `frontend/lib/dev/schedules_preview.dart`; в `.claude/launch.json`
  два конфига — `schedules-preview` (flutter run, в панели падает по DDS) и
  `schedules-preview-static` (после `flutter build web -t lib/dev/schedules_preview.dart -o build/preview-schedules`).
- `flutter test test/schedule/` — 155 зелёных; `dart analyze` по правкам чист.
  `make lint`/`make test` не гонялись — бэкенд не трогался. Ничего не закоммичено.

## Не доделано

- Тап по значку не подключён и сервер `defects_count` не отдаёт — это S02.

## Следующий этап

**Цель.** S02: в строке раздела число дефектных актов приходит из API, тап по
значку открывает список дефектов объекта за год.

**Готово, когда.** На живых данных (`app-live` или `make up`) у объекта с актами
в строке стоит верное число, тап открывает тот же список, что в карточке
объекта; у объекта без актов значок серый.

## Первые шаги

1. Как карточка объекта берёт число и открывает список: `frontend/lib/foreman/defects/live_defects_badge.dart`
   и `frontend/lib/foreman/object_foreman/object_page_foreman.dart:1258` (`LiveDefectsBadge`, `onDefectsTap`).
2. Ручка ленты — `grep -rn "schedules" backend/src/api/api_v1/endpoints/ | head`; добавить
   `defects_count` за год в ответ строк (считать на сервере, не по строке с клиента).
3. Разбор ответа: `frontend/lib/screns/schedule/repository/api_schedules_repository.dart`
   и `test/schedule/api_schedules_repository_test.dart`; тап — в `_BadgeSlot`
   через колбэк из `SchedulesScreen` (по образцу `onRowTap`).

## Не трогать

- E02 (статистика, отчёты, PDF с двойным доменом) и E04–E09.
- Старый код ряда удалять только в S03, после проверки на стеке.
- `flutter pub get` — не запускать.

## Уточнить перед стартом

- Считать `defects_count` в той же ручке ленты или отдельной ручкой на страницу.

## Ссылки

- `.claude/plan/E01-grafiki.md` — критерии S02/S03.
- `els-vault/inbox/иконка дефектных актов в окне графика - документ с бейджем количества.md` — что просил заказчик.
