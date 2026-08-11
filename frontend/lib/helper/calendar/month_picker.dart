import 'package:flutter/material.dart';

import '../class_colors.dart';

/// Названия месяцев списком, а не через `DateFormat('LLLL', 'ru')`.
///
/// Данные русской локали `intl` в этом приложении нигде не инициализируются
/// явно — они приезжают побочным эффектом `GlobalMaterialLocalizations`.
/// Стоит порядку загрузки измениться, и форматирование падает
/// `LocaleDataException` уже в проде. Двенадцать строк такого не умеют.
const List<String> kMonthsNominative = <String>[
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const List<String> kMonthsShort = <String>[
  'Янв',
  'Фев',
  'Мар',
  'Апр',
  'Май',
  'Июн',
  'Июл',
  'Авг',
  'Сен',
  'Окт',
  'Ноя',
  'Дек',
];

/// Выбор месяца и года для виджетов статистики на главной.
///
/// Зачем отдельный виджет, если рядом лежит [MyDataCalendar]. Тот — обёртка
/// над `SfDateRangePicker` с выбором диапазона дат: стрелки в нём нарисованы,
/// но ничего не делают, а выбранный диапазон никуда не уходит. Статистике
/// нужен ровно один календарный месяц, и его нужно отдавать наружу.
///
/// Виджет без состояния: месяц хранит родитель и присылает через [value],
/// а изменения получает через [onChanged].
class MonthPicker extends StatelessWidget {
  const MonthPicker({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  /// Выбранный месяц. День внутри значения не используется.
  final DateTime value;

  final ValueChanged<DateTime> onChanged;

  /// На время загрузки стрелки гасятся, чтобы быстрые клики не отправляли
  /// пачку запросов, ответы которых придут вперемешку.
  final bool enabled;

  /// Месяц вперёд от текущего смысла не имеет: поломок в будущем не бывает.
  bool get _canGoForward {
    final DateTime now = DateTime.now();
    return value.year < now.year ||
        (value.year == now.year && value.month < now.month);
  }

  void _shift(int months) {
    onChanged(DateTime(value.year, value.month + months));
  }

  Future<void> _pick(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initial: value),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = '${kMonthsNominative[value.month - 1]} ${value.year}';
    final bool forwardEnabled = enabled && _canGoForward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left,
          onPressed: enabled ? () => _shift(-1) : null,
          tooltip: 'Предыдущий месяц',
        ),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(6.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right,
          onPressed: forwardEnabled ? () => _shift(1) : null,
          tooltip: 'Следующий месяц',
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: 20.0,
      splashRadius: 18.0,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
      color: ColorApp.myColorBlack,
      disabledColor: ColorApp.myColorGrayBorder,
    );
  }
}

/// Диалог «год + сетка месяцев». Прыгнуть на декабрь прошлого года через
/// стрелки — двенадцать кликов, поэтому нужен прямой выбор.
class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({Key? key, required this.initial}) : super(key: key);

  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  bool _isInFuture(int month) {
    final DateTime now = DateTime.now();
    return _year > now.year || (_year == now.year && month > now.month);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Переключатель года
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year -= 1),
                  icon: const Icon(Icons.chevron_left),
                  splashRadius: 20.0,
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
                IconButton(
                  onPressed:
                      _year < now.year ? () => setState(() => _year += 1) : null,
                  icon: const Icon(Icons.chevron_right),
                  splashRadius: 20.0,
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              physics: const NeverScrollableScrollPhysics(),
              children: List<Widget>.generate(12, (int index) {
                final int month = index + 1;
                final bool selected = _year == widget.initial.year &&
                    month == widget.initial.month;
                final bool disabled = _isInFuture(month);

                return OutlinedButton(
                  onPressed: disabled
                      ? null
                      : () => Navigator.of(context).pop(DateTime(_year, month)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        selected ? ColorApp.myColorGreenLine : Colors.transparent,
                    side: BorderSide(
                      color: selected
                          ? ColorApp.myColorGreenAuth
                          : ColorApp.myColorGrayBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    kMonthsShort[index],
                    style: TextStyle(
                      color: disabled
                          ? ColorApp.myColorGrayText
                          : ColorApp.myColorBlack,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Отмена',
            style: TextStyle(color: ColorApp.myColorGray),
          ),
        ),
      ],
    );
  }
}
