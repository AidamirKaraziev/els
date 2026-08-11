---
tags: [pattern, статистика, sql]
date: 2026-08-11
---

# Статистика - агрегаты за период через FILTER и общий подзапрос

Запросы виджетов главной живут в `src/crud/crud_statistics.py`, отдельно от
`crud_order`: у всех четырёх виджетов общий период и общие фильтры, а своей
модели у статистики нет.

Базовый отбор собирается один раз и переиспользуется всеми методами:

```python
def _breakdowns_query(self, *, db, period, division_id=None, ...):
    query = (
        db.query(Order)
        .join(Object, Order.object_id == Object.id)
        .outerjoin(FaultCategory, Order.fault_category_id == FaultCategory.id)
        .filter(
            Order.created_at >= period.start,
            Order.created_at < period.end,
            (Order.fault_category_id.is_(None))
            | (FaultCategory.counts_as_breakdown.is_(True)),
        )
    )
    if division_id is not None:
        query = query.filter(Object.division_id == division_id)
    return query
```

Вызывающий добавляет свою группировку через `.with_entities()`. Несколько
разных агрегатов снимаются за один проход по таблице через `FILTER`:

```python
func.count(Order.id).label("breakdown_count"),
func.avg(reaction_seconds).filter(reaction_is_sane).label("avg_reaction"),
func.count(Order.id).filter(reaction_is_sane).label("reacted_count"),
```

SQLAlchemy 1.4 это поддерживает и рендерит в PostgreSQL
`avg(...) FILTER (WHERE ...)`.

## Почему так

- Период — всегда полуинтервал `[start, end)`. Включающая правая граница
  затягивает первую заявку следующего месяца, и декабрь ломается отдельно,
  потому что конец периода уезжает в другой год.
- `FILTER` вместо отдельных запросов на каждый агрегат: один проход вместо
  четырёх, и все числа заведомо из одной выборки.
- Отрицательные разницы времени отбрасываются прямо в условии `FILTER`:
  одна битая запись, где заявку «приняли» раньше, чем создали, утащила бы
  среднее в минус.

## Что важно не забыть

- Разбивку по категориям внутри объекта считать **только для объектов,
  попавших в выдачу**. Иначе на тысяче лифтов запрос вернёт данные, которые
  никто не покажет.
- `limit` режет список, но не итоги: «показано 5 из 23» требует отдельного
  запроса `count_breakdown_objects`, а не `len(items)`.
- Тесты этого модуля надо проверять мутациями. 36 тестов прошли с первого
  запуска — это ничего не значило, пока три внесённые в запрос ошибки не
  уронили ровно 10 из них.

Дальше этот подзапрос переиспользуют просроченные ТО, выполнение графиков и
топ сотрудников.

Связано:
[[справочник поломок - флаг counts_as_breakdown вместо списка id в коде]],
[[тяжесть категории - порядок берётся из id, отдельного ранга нет]],
[[паттерн API - endpoints to crud to schemas to models]]
