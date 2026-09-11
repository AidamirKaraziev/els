---
этап: E02·S06 — проверка на собранном стеке и удаление замещённого кода
статус: закрыт
дата: 2026-09-11
план: .claude/plan/roadmap.md
---

# Передача: E02 закрыт 9/9; следующий — E03 «Единая навигация», подплана ещё нет

## Сделано и проверено

- На `make up` (http://localhost:8080) прораб проходит путь: «Отчёты» →
  плитка «Дефектных актов 6» → «открыть список» (6, совпадает) → матрица,
  две галочки на разных страницах → «PDF по выбранным». PDF по
  `object_ids=33&object_ids=82`: «Объектов в отчёте: 2», раздел
  «Дефектные акты за период — Всего: 2», 4 страницы.
- Починен баг, найденный на стенде: после выгрузки бло́к отдавал
  `WorksReportExportReady`, и пейджер (рисуется только при `Loaded`)
  пропадал. Теперь `_onExportRequested` в
  `frontend/lib/screns/report/bloc/works_report_bloc.dart` после
  ExportReady/ExportFailed эмитит прежнее состояние; тест
  «после выгрузки экран возвращается на ту же страницу отчёта» в
  `frontend/test/report/export_selected_test.dart`.
- Удалён мёртвый код подрядчика: `helper/defective_act.dart` (старый диалог
  акта), `helper/sideMenu/sideMenu.dart` (дубль `MyDrawer`),
  `my_test_screen.dart`.
- Проверки: `make lint` чист, `make test` — 1009, `flutter test test/report`
  — 8, `dart analyze lib test` — 0 ошибок (961 инфо подрядчика, было 970),
  `flutter build web` собран.
- Не закоммичено: см. `git status` — правки бэка нет, весь дифф фронт + план.

## Не доделано

- Остальные файлы фронта без единой ссылки, вне темы E02 — не трогал:
  `widgets_create/create_contract.dart`, `helper/creation_plot.dart`,
  `helper/calendar/calendar.dart`, `mechanic/screens/soon_screen.dart`,
  `screns/object/repository/repository_object.dart`,
  `foreman/companies_foreman/company_widget_foreman/add_companies_foreman.dart`,
  `foreman/object_foreman/widgets_object_foreman/object_account_freeze_foreman.dart`.
  Поиск: файл, чьё имя не встречается в `frontend/lib` вне `dev/`.
- Стрелки пейджера не скроллят к началу матрицы — сознательно, см. прошлую
  передачу.

## Следующий этап

**Цель.** E03 «Единая навигация»: на главной прораба общий топ сотрудников,
один бургер для админа и прораба. Подплана нет — сначала `/plan E03`.

**Готово, когда.** Определяется в `/plan E03`; ориентир из roadmap — один
и тот же drawer у обеих ролей, топ сотрудников на главной прораба.

## Первые шаги

1. `/plan E03` — нарезать этапы; входные точки: `frontend/lib/foreman/home_foreman.dart`
   (оболочка прораба, индексы экранов), `frontend/lib/foreman/drawer_foreman.dart`,
   `frontend/lib/helper/my_drawer/my_drawer.dart` (drawer админа),
   `frontend/lib/screns/home/top_employees/top_employees.dart`.
2. Кадр макета: попросить выгрузить главную прораба и бургер в `~/els-figma/`.
3. Перед кодом — набросок по фикстуре, как в E01/E02.

## Не трогать

- `screns/report/*` и `/reports/works*` — приняты, E02 закрыт.
- `schedule_page.dart` и старый экран графика — S2.6 другого плана.
- `export-link`: значения в query не экранируются — отдельная задача.

## Уточнить перед стартом

- Знание E02 записано в vault 11 сентября; стартовать сразу с `/plan E03`.

## Ссылки

- `.claude/plan/roadmap.md` — E03 в «Дальше», подплана нет.
- `frontend/lib/foreman/home_foreman.dart` — список экранов прораба по индексам.
