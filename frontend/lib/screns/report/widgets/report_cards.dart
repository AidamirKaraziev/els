/// Общие детали шторок отчёта: ручка сверху, карточка с цветной полосой,
/// бейдж состояния и заглушка по центру. Вынесены из шторки объекта, когда
/// появилась вторая шторка — список актов за период; две копии разъехались
/// бы.
library;

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Полоска-ручка в верху шторки.
class ReportSheetHandle extends StatelessWidget {
  const ReportSheetHandle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        width: 40.0,
        height: 4.0,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: ColorApp.myColorGrayBorder,
          borderRadius: BorderRadius.circular(2.0),
        ),
      );
}

/// Заглушка по центру шторки: ошибка, пустой период.
class ReportCentered extends StatelessWidget {
  const ReportCentered({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 34.0, color: ColorApp.myColorGrayText),
          const SizedBox(height: 12.0),
          Text(title, textAlign: TextAlign.center),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6.0),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 16.0),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({Key? key, required this.accent, required this.child})
      : super(key: key);

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorGrayBorder),
      ),
      // Цветная полоса слева, а не заливка карточки: сплошной цвет кричит, а
      // нужен спокойный признак вида работы. Тот же приём, что в строке
      // просроченных ТО, где заливку заменили бейджем.
      //
      // `IntrinsicHeight` обязателен: карточка лежит в `ListView`, где высота
      // не ограничена, и `stretch` без него просит бесконечную высоту —
      // лента шторки оставалась пустой белой, ошибка была только в консоли.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 3.0,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({Key? key, required this.label, required this.color})
      : super(key: key);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.0)),
    );
  }
}
