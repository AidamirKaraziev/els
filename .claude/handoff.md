---
этап: E01·S03 — проверка на собранном стеке и чистка раздела «Графики»
статус: закрыт
дата: 2026-09-10
план: .claude/plan/E01-grafiki.md
---

# Передача: E01 закрыт целиком (3/3), следующего этапа в плане нет

## Сделано и проверено

- Прораб на `make up` (http://localhost:8080, вкладка «График»): ряд крупный,
  у объекта «AAAAAAAAAAAA» красный значок «3»; тап по значку открывает
  «Дефекты» за 2026 с тремя актами; назад — строка перечитана
  (`GET /schedules/rows?object_id=80&year=2026`).
- Удалён `frontend/lib/screns/schedule/widgets/schedule_year_dialog.dart`
  (`pickScheduleYear` никто не вызывал) и `_statusFor` из
  `object/repository/fixture_schedule_object_repository.dart`. Ссылок нет.
- `dart analyze lib/screns/schedule` — 0 issues; `flutter test test/schedule/`
  — 159 зелёных; `flutter build web` собрана; `make lint` чист.
  `make test` в этой сессии не гонялся — бэкенд не менялся.
- Фронт-образ пересобран `--no-cache` (кэшированная сборка давала тот же
  image id: удалённый код был мёртвым и в `build/web` не попадал).
- Коммит `37bb0b3` (вместе с handoff/планом/ledger по S02).

## Следующий этап

**Цель.** В плане открытых этапов нет: E02–E09 без подпланов. Следующий
шаг — `/plan E02` (статистика, отчёты, PDF) или то, что назовёт заказчик.

**Готово, когда.** Определяется при нарезке следующего эпика.

## Первые шаги

1. `python3 ~/.claude/skills/lib/counters.py` — убедиться, что E01 3/3.
2. `/plan E02` — нарезать подплан; критерии брать из `.claude/plan/roadmap.md`.

## Не трогать

- `LiveDefectsBadge` в `frontend/lib/foreman/object_foreman/object_page_foreman.dart:1258`
  — чужая карточка объекта, в E01 сознательно не входила.
- Dev-точки `frontend/lib/dev/*_preview.dart` — в сборку не попадают, это
  конвенция модуля, не мусор.
- `flutter pub get` — не запускать.

## Уточнить перед стартом

- Какой эпик следующий: E02 по roadmap или срочное от заказчика после сдачи.

## Ссылки

- `.claude/plan/roadmap.md` — порядок эпиков E02–E09.
- `els-vault/00-home/текущие приоритеты.md` — открытое вне плана.
