---
tags: [pattern, фронт, вёрстка]
date: 2026-08-11
---

# Виджеты главной - Expanded по LayoutBuilder, а не по ширине экрана

Карточка статистики может стоять в двух разных местах с разными
ограничениями. В `home_screen.dart` она внутри `Expanded` — высота конечная,
список надо растягивать. В `desktop_version.dart` она внутри
`SingleChildScrollView` — высота бесконечная, и `Expanded` там роняет вёрстку
с «RenderFlex children have non-zero flex but incoming height constraints are
unbounded».

Ширина экрана об этом не говорит ничего. Спрашиваем у родителя:

```dart
child: LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) {
    final bool bounded = constraints.maxHeight.isFinite;
    return Column(
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        header,
        if (bounded) Expanded(child: body) else body,
      ],
    );
  },
),
```

Внутри тела то же самое: `ListView` при `bounded`, обычная `Column` иначе.

## Почему так

- `Responsive.isMobile(context)` отвечает на вопрос про ширину, а `Expanded`
  спрашивает про высоту. Связь между ними держится только на том, кто и куда
  встроил виджет, — и ломается молча при первом же переносе.
- Виджет становится встраиваемым куда угодно: в карточку, в диалог, в лист
  прокрутки. Для четырёх виджетов главной это существенно, они переезжают.

## Что важно не забыть

- `isMobile` остаётся, но только для плотности: компактные чипы, размер
  шрифта, скрытие колонки «Ответственный» на экране уже 430 точек. Это
  действительно про ширину.
- Пустое состояние и индикатор загрузки тоже зависят от `bounded`: без
  ограниченной высоты им нужен свой размер, иначе `Column` схлопнется по
  высоте иконки.
- `desktop_version.dart` сейчас мёртвый код, на него никто не ссылается. Это
  не повод оставлять в виджете ловушку.

Связано: [[аудит фронта на 2026-08-11 - Flutter, 71 тысяча строк]]
