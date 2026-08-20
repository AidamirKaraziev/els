/// «Информация о ТО (подробнее)» — кадр `1826:329`.
///
/// Строк здесь меньше, чем в кадре, и это не упрощение, а предел данных.
/// `GET /act-fact/{id}/` отдаёт прораба и механика **числами** (`foreman_id`,
/// `main_mechanic_id`), имён в ответе нет; `GET /act-fact/for-me` не отдаёт и
/// их. Показать «Прораб: 14» хуже, чем не показать строку вовсе, а тянуть
/// карточки людей ради подписи — лишний запрос на экране, который механик
/// открывает в подвале. Появятся имена в ответе — строки добавятся сюда.
///
/// Оформление — группы строк с серой подписью, как в личном кабинете
/// (`1826:283`): это единственный кадр механика, где такие группы уже есть.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/acts.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';

class MechanicActInfoScreen extends StatelessWidget {
  const MechanicActInfoScreen({
    Key? key,
    required this.task,
    required this.act,
    this.startedAt,
    this.finishedAt,
  }) : super(key: key);

  final MechanicTask task;
  final ActDetails? act;

  /// Отметки о ходе работы — целые секунды из строки списка ТО.
  final int? startedAt;
  final int? finishedAt;

  @override
  Widget build(BuildContext context) {
    final ActDetails? act = this.act;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: const Text('Подробнее о ТО', style: MechanicLayout.sectionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MechanicLayout.screenPadding,
          16.0,
          MechanicLayout.screenPadding,
          32.0,
        ),
        children: <Widget>[
          _Group(
            label: 'Объект',
            rows: <_Row>[
              _Row('Название', task.title),
              _Row('Адрес', task.address ?? '—'),
            ],
          ),
          const SizedBox(height: 16.0),
          _Group(
            label: 'График',
            rows: <_Row>[
              _Row('Плановый срок', _due()),
              _Row('Регламент', act?.title ?? '—'),
              _Row('Акт', '№ ${task.id}'),
            ],
          ),
          const SizedBox(height: 16.0),
          _Group(
            label: 'Ход работы',
            rows: <_Row>[
              _Row('Начато', _day(startedAt)),
              _Row('Закрыто', _day(finishedAt)),
              _Row(
                'Пройдено',
                act == null || act.empty
                    ? '—'
                    : progressText(act.doneCount, act.total),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _due() {
    final int? year = asInt(task.raw['year']);
    final int? month = asInt(task.raw['month']);
    if (year == null || month == null) return '—';
    final String text = monthText(year, month);
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  static String _day(int? seconds) =>
      seconds == null ? '—' : dayText(seconds);
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String value;
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.rows});

  final String label;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(label, style: MechanicLayout.groupLabel),
        ),
        Container(
          decoration: BoxDecoration(
            color: ColorApp.myColorWhite,
            borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < rows.length; index++)
                Container(
                  decoration: BoxDecoration(
                    border: index == rows.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: MechanicLayout.divider),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 110.0,
                        child: Text(
                          rows[index].label,
                          style: MechanicLayout.rowLabel,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[index].value,
                          style: MechanicLayout.rowValue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
