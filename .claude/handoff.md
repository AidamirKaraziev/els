---
этап: E01·S02 — число дефектных актов из API и тап на список за год
статус: закрыт
дата: 2026-09-10
план: .claude/plan/E01-grafiki.md
---

# Передача: S02 закрыт и проверен на стенде, остался S03 — стек и чистка

## Сделано и проверено

- `GET /schedules/rows` отдаёт `defects_count` — подзапрос в
  `backend/src/crud/crud_schedules.py:_defects_count` (год создания, только
  `kind == internal`, как в `crud_defective_act.get_by_object_and_year`).
  Схема `ScheduleRow.defects_count: int = 0`, старый контракт цел.
- В строке раздела «Графики» число от сервера; тап по значку открывает
  `DefectsScreen(objectId, objectName, initialYear: row.year)` из
  `schedules_screen.dart:_onDefectsTap`, по возвращении строка перечитывается
  (`SchedulesRowRefreshed`).
- Проверки: `make lint` чист, `make test` — 996 зелёных,
  `flutter test test/schedule/` — 159 зелёных (4 новых: ручка, репозиторий,
  тап значка в строке, открытие списка с экрана).
- Живой стенд `make up` под админом: числа 3/2/серый ноль совпадают с
  карточкой объекта, тап открывает список за 2026, строка перечитывается.
- Коммит `c34e80b`.

## Следующий этап

**Цель.** S03: прораб проходит сценарий эпика на собранном стеке; код
подрядчика, который новый ряд заменил, удалён.

**Готово, когда.** На `make up` прораб (не админ) видит ряд крупно, число
актов и список по тапу; удалённый старый код не оставил ссылок;
`dart analyze lib/screns/schedule` чист (сейчас там одно чужое предупреждение
`_statusFor` в `fixture_schedule_object_repository.dart:96`); `flutter test
test/schedule/` зелёный.

## Первые шаги

1. `git show c2a7c2c --stat` и `git show c34e80b --stat` — что новое заменило;
   искать мёртвое: `grep -rn "kRowHeight\|_BadgeSlot\|DefectsBadge" frontend/lib`
   и старые константы/виджеты ряда в `frontend/lib/screns/schedule/widgets/`.
2. Стенд: `make up`, в панели браузера http://localhost:8080 — вход прорабом
   делает пользователь (пароли не вводить), вкладка «Графики» вторая снизу.
3. После чистки: `dart analyze lib/screns/schedule`, `flutter test test/schedule/`,
   `flutter build web` — сборка должна собираться без удалённого.

## Не трогать

- E02 (статистика, отчёты, PDF) и E04–E09.
- `flutter pub get` — не запускать.
- Бэкенд — S03 фронт+infra; ручку ленты не менять.

## Уточнить перед стартом

- Что именно считается «старым кодом окна» в S03: только остатки в
  `screns/schedule/widgets/`, или и `LiveDefectsBadge` в карточке объекта
  подрядчика (`foreman/object_foreman/object_page_foreman.dart:1258`).

## Ссылки

- `.claude/plan/E01-grafiki.md` — критерий S03 и цель эпика.
- `els-vault/knowledge/decisions/код подрядчика удаляем, а не обходим.md` — правило чистки.
