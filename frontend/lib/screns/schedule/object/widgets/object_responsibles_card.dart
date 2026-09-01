import 'package:flutter/material.dart';

import '../../../../helper/api_image.dart';
import '../../../../helper/class_colors.dart';
import '../models/schedule_object_card.dart';
import '../models/schedule_responsible.dart';
import 'object_block.dart';

/// Блок «Ответственные»: две зелёные плашки — прораб и механик.
///
/// На узком экране плашки встают друг под друга: рядом им не хватает ширины,
/// и подпись роли ломалась пополам — «Про / раб».
///
/// Подрядчик рисует здесь ещё два состояния — «Прораб удалён» красным и
/// «Прораб заморожен» синим. На кадре их нет, и в каркасе мы их не повторяем:
/// объект без назначенного человека просто не показывает свою плашку.
class ObjectResponsiblesCard extends StatelessWidget {
  const ObjectResponsiblesCard({
    Key? key,
    required this.card,
    this.onOpen,
  }) : super(key: key);

  /// Ширина, ниже которой две плашки перестают помещаться в ряд.
  ///
  /// Взята по месту: на меньшей ширине белая пилюля с фамилией сжимает
  /// подпись роли до переноса, и «Прораб» читается как «Про раб».
  static const double _rowWidth = 620.0;

  final ScheduleObjectCard card;

  /// Открыть карточку этого человека. Не задан — плашки не нажимаются:
  /// экран графика сам решает, есть ли куда вести.
  final void Function(ScheduleResponsible person)? onOpen;

  @override
  Widget build(BuildContext context) {
    final bool inRow = MediaQuery.of(context).size.width >= _rowWidth;
    final List<ScheduleResponsible> people = <ScheduleResponsible>[
      if (card.foreman != null) card.foreman!,
      if (card.mechanic != null) card.mechanic!,
    ];
    return ObjectBlock(
      title: 'Ответственные',
      child: people.isEmpty
          ? Container(
              height: 84.0,
              decoration: objectCardDecoration(),
              child: const Center(
                child: Text(
                  'Ответственные не назначены',
                  style: TextStyle(color: ColorApp.myColorGrayText),
                ),
              ),
            )
          : inRow
              ? Row(
                  children: <Widget>[
                    for (int i = 0; i < people.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 20.0),
                      Expanded(
                        child: _ResponsibleTile(
                          person: people[i],
                          onOpen: onOpen,
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < people.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 16.0),
                      _ResponsibleTile(person: people[i], onOpen: onOpen),
                    ],
                  ],
                ),
    );
  }
}

/// Зелёная плашка: подпись роли слева, белая пилюля с фото и фамилией справа.
///
/// Нажимается только когда у человека есть id и есть куда вести: плашка,
/// которая «нажимается» и ничего не делает, хуже неподвижной.
class _ResponsibleTile extends StatelessWidget {
  const _ResponsibleTile({Key? key, required this.person, this.onOpen})
      : super(key: key);

  final ScheduleResponsible person;
  final void Function(ScheduleResponsible person)? onOpen;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _tile();
    if (onOpen == null || person.id == null) return tile;
    return Material(
      // Именно прозрачный: `myColorTransparent` в палитре — светло-серый
      // фон экрана, и он бы закрасил зелёную плашку по углам.
      color: Colors.transparent,
      borderRadius: _radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: _radius,
        onTap: () => onOpen!(person),
        child: tile,
      ),
    );
  }

  static final BorderRadius _radius = BorderRadius.circular(10.0);

  Widget _tile() {
    return Container(
      height: 84.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: _radius,
        color: ColorApp.myColorGreen,
      ),
      child: Row(
        children: <Widget>[
          // Подпись роли занимает ровно свою ширину и не переносится: место
          // ей уступает пилюля, а не наоборот. С `Expanded` короткое слово
          // «Прораб» ломалось пополам, едва пилюле становилось тесно.
          Text(
            person.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: ColorApp.myColorWhite,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              height: 60.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: ColorApp.myColorWhite,
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 20.0,
                    backgroundColor: ColorApp.myColorAvatar,
                    backgroundImage: const AssetImage('assets/user.png'),
                    // Фото сотрудника поверх заглушки: пока оно не пришло —
                    // и если не придёт вовсе — виден серый силуэт, а не дыра.
                    foregroundImage: (person.photo == null ||
                            person.photo!.isEmpty)
                        ? null
                        : apiImage(person.photo),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      person.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: ColorApp.myColorBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
