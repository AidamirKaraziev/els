import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../models/schedule_object_card.dart';
import 'object_block.dart';

/// Блок «Информация об объекте»: белая карточка со списком полей.
///
/// Состав и порядок строк — по кадру `1182:232`. У подрядчика первая строка
/// подписана «Название» и показывает имя объекта; на кадре это «Организация»,
/// и берём кадр.
///
/// Телефон контактного лица на кадре не нарисован, но строка оставлена по
/// просьбе заказчика: с этого экрана звонят, и ходить за номером в карточку
/// объекта значит терять открытый график.
class ObjectInfoCard extends StatelessWidget {
  const ObjectInfoCard({Key? key, required this.card}) : super(key: key);

  final ScheduleObjectCard card;

  @override
  Widget build(BuildContext context) {
    return ObjectBlock(
      title: 'Информация об объекте',
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: objectCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _InfoRow(
              icon: Icons.domain_outlined,
              title: 'Организация',
              value: card.organization,
            ),
            _InfoRow(
              icon: Icons.signpost_outlined,
              title: 'Участок',
              value: card.division,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'Адрес',
              value: card.address,
            ),
            _InfoRow(
              icon: Icons.looks_one_outlined,
              title: 'Тип',
              value: card.type,
            ),
            _InfoRow(
              icon: Icons.elevator_outlined,
              title: 'Модель',
              value: card.model,
            ),
            _InfoRow(
              icon: Icons.filter_1_outlined,
              title: 'Регистрационный номер',
              value: card.registrationNumber,
            ),
            _InfoRow(
              icon: Icons.filter_1_outlined,
              title: 'Заводской номер',
              value: card.factoryNumber,
            ),
            _InfoRow(
              icon: Icons.apartment_outlined,
              title: 'Компания',
              value: card.company,
            ),
            _InfoRow(
              icon: Icons.person_outline,
              title: 'Контактное лицо',
              value: card.contactPerson,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              title: 'Телефон',
              value: card.contactPhone,
            ),
            _InfoRow(
              icon: Icons.assignment_outlined,
              title: 'Договор',
              value: card.contract,
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Одна строка карточки: зелёная иконка слева, серая подпись и значение.
///
/// Пустое значение показываем прочерком, а строку не прячем: список полей на
/// кадре одинаковой длины у всех объектов, и исчезающие строки заставляли бы
/// человека вспоминать, какой по счёту здесь заводской номер.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? value;

  /// Последняя строка — без нижнего отступа, иначе карточка снизу пустует.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final String text = (value == null || value!.isEmpty) ? '—' : value!;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0.0 : 26.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 26.0, color: ColorApp.myColorGreenAuth),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: ColorApp.myColorBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
