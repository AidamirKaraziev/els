/// Значок-счётчик дефектных актов объекта за год.
///
/// Место и вид взяты с кадра `1182:232`: там у заголовка «Техническое
/// обслуживание» стоит `mdi:file-document-alert-outline` 24×24 янтарного
/// `#F0BB00`, рядом с иконкой выгрузки. Расхождения с кадром, принятые
/// сознательно:
///
/// * **Числа на кадре нет** — там документ с восклицательным знаком, один и
///   тот же при любом количестве дефектов. Число нужнее знака: прораб
///   открывает список ради него.
/// * **Цвет красный, а не янтарный.** Янтарный на кадре — цвет
///   предупреждения вообще; здесь значок говорит «за год есть дефекты», и он
///   в одном ряду с красными состояниями клеток ленты.
/// * **Серого состояния на кадре нет вовсе** — значок там нарисован в
///   единственном виде. При нуле красный значок читался бы как тревога на
///   ровном месте, поэтому нулю дан свой вид: серый документ без числа.
///
/// «Дефектных актов не было» сказано подсказкой, а не текстом рядом: значок
/// стоит в строке заголовка вместе с переключателем года, и подпись оттуда
/// вытесняет либо год, либо сам заголовок. Решено 6 сентября 2026 глазами на
/// наброске `dev/defects_badge_preview.dart`, где были показаны оба варианта.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';

class DefectsBadge extends StatelessWidget {
  const DefectsBadge({
    Key? key,
    required this.count,
    required this.year,
    this.onTap,
  }) : super(key: key);

  /// Сколько дефектных актов у объекта за [year]. Считаются только
  /// внутренние: клиентские — порождённые записи, они видны из своего
  /// первоисточника и второй раз считаться не должны.
  final int count;

  /// Год, за который посчитано. Идёт в подсказку и дальше в список.
  final int year;

  final VoidCallback? onTap;

  bool get _empty => count <= 0;

  String get _hint => _empty
      ? 'Дефектных актов не было за $year год'
      : 'Дефектных актов за $year год: $count';

  @override
  Widget build(BuildContext context) {
    final Color color = _empty ? ColorApp.myColorGrayText : ColorApp.myColorRed;

    return Tooltip(
      message: _hint,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          // Справа больше: под выносное число, иначе соседний переключатель
          // года наезжает на пилюлю.
          padding: EdgeInsets.fromLTRB(4.0, 4.0, _empty ? 4.0 : 12.0, 4.0),
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(Icons.description_outlined, size: 24.0, color: color),
                if (!_empty)
                  Positioned(
                    right: -6.0,
                    top: -4.0,
                    child: _Counter(count: count),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Число в красной пилюле поверх уголка документа.
///
/// Пилюля, а не круг: с трёхзначным числом круг растягивается в овал с
/// обрезанными цифрами, а на объекте за год дефектов бывает и больше сотни.
class _Counter extends StatelessWidget {
  const _Counter({Key? key, required this.count}) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16.0),
      height: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorRed,
        borderRadius: BorderRadius.circular(8.0),
        // Обводка цветом фона: значок стоит на белой карточке, и без неё
        // пилюля сливается с уголком документа под ней.
        border: Border.all(color: ColorApp.myColorWhite, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10.0,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: ColorApp.myColorWhite,
        ),
      ),
    );
  }
}
