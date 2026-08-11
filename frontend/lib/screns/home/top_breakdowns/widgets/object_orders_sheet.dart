import 'package:flutter/material.dart';

import '../../../../helper/calendar/month_picker.dart';
import '../../../../helper/class_colors.dart';
import '../models/breakdowns_report.dart';
import '../repository/breakdowns_repository.dart';

/// Заявки одного объекта за месяц — что открывается кликом по строке.
///
/// Показываем прямо здесь, а не уводим на экран задач: там своя загрузка всех
/// заявок разом и своя фильтрация, встраивать в неё period и объект — значит
/// переписывать семисотстрочный экран ради одного перехода.
///
/// Запрос идёт с `only_breakdowns`, поэтому длина списка совпадает со
/// счётчиком в строке. Иначе человек увидел бы девять заявок вместо шести и
/// решил, что виджет считает неправильно.
class ObjectOrdersSheet extends StatefulWidget {
  const ObjectOrdersSheet({
    Key? key,
    required this.item,
    required this.month,
    this.repository = const BreakdownsRepository(),
  }) : super(key: key);

  final BreakdownObject item;
  final DateTime month;
  final BreakdownsRepository repository;

  @override
  State<ObjectOrdersSheet> createState() => _ObjectOrdersSheetState();
}

class _ObjectOrdersSheetState extends State<ObjectOrdersSheet> {
  List<BreakdownOrder>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _orders = null;
      _error = null;
    });
    try {
      final List<BreakdownOrder> orders =
          await widget.repository.fetchObjectOrders(
        objectId: widget.item.objectId,
        year: widget.month.year,
        month: widget.month.month,
      );
      if (!mounted) return;
      setState(() => _orders = orders);
    } on BreakdownsException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String period =
        '${kMonthsNominative[widget.month.month - 1]} ${widget.month.year}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: ColorApp.myColorGrayBorder,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            widget.item.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18.0),
          ),
          Text(
            [widget.item.address, widget.item.client, period]
                .where((String? part) => part != null && part.trim().isNotEmpty)
                .join(' · '),
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 12.0),
          Flexible(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Text(
              _error!,
              style: const TextStyle(color: ColorApp.myColorGray),
            ),
            TextButton(
              onPressed: _load,
              child: const Text(
                'Повторить',
                style: TextStyle(color: ColorApp.myColorGreenAuth),
              ),
            ),
          ],
        ),
      );
    }

    final List<BreakdownOrder>? orders = _orders;
    if (orders == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: ColorApp.myColorGreenAuth,
            ),
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      // Счётчик в строке был не нулевой, иначе строки бы не было. Значит
      // расхождение — повод сказать об этом прямо, а не показать пустоту.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          'Заявок за этот месяц не нашлось',
          style: TextStyle(color: ColorApp.myColorGray),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 16.0),
      itemBuilder: (_, int index) => _OrderTile(order: orders[index]),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({Key? key, required this.order}) : super(key: key);

  final BreakdownOrder order;

  String get _date {
    final DateTime? created = order.createdAt;
    if (created == null) return '';
    final String day = created.day.toString().padLeft(2, '0');
    final String month = kMonthsShort[created.month - 1].toLowerCase();
    final String hour = created.hour.toString().padLeft(2, '0');
    final String minute = created.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (order.categoryCode != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: ColorApp.myColorTransparent,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  order.categoryCode!,
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                _date,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ),
            if (order.statusName != null)
              Text(
                order.statusName!,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGray,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(order.taskText ?? 'Без описания'),
        if (order.categoryName != null)
          Text(
            order.categoryName!,
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
        if (order.executor != null)
          Text(
            'Исполнитель: ${order.executor}',
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
      ],
    );
  }
}
