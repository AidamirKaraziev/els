import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:flutter/material.dart';

import '../../../helper/api_config.dart';
import '../../../helper/class_colors.dart';

/// Статус «Выполнено» из справочника `statuses`.
///
/// Справочник заполняется данными, а не кодом, поэтому id зафиксирован здесь
/// одним местом: 1 Создано, 2 Принято, 3 В процессе, 4 Выполнено, 5 Проблема.
const int kActStatusDone = 4;

/// Завершить ТО: проставить акту дату окончания и статус «Выполнено».
///
/// `finished_at` уходит меткой времени в секундах — так его ждёт схема
/// `ActFactUpdate` на бэкенде. Возвращает `true`, если сервер принял изменение.
Future<bool> finishFactAct(int actId) async {
  final response = await Api.put(
    Uri.parse('${ApiConfig.base}/act-fact/$actId/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: json.encode(<String, dynamic>{
      'finished_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'status_id': kActStatusDone,
    }),
  );
  return response.statusCode == 200;
}

/// Кнопка «Завершить ТО» под выбранным месяцем графика.
///
/// Единственное место в приложении, где акт получает `finished_at`. До неё
/// закрыть ТО было нечем: экран заканчивался списком работ, а поля даты не
/// касался никто — в боевой базе все акты стояли со статусом «Создано» и
/// пустой датой окончания.
///
/// От этой даты считается виджет «Выполнение графика» на главной, поэтому
/// закрытие сделано явным действием человека, а не побочным эффектом
/// сохранения списка работ: прораб отмечает работы по ходу дела, а закрывает
/// ТО один раз.
class FinishTOButton extends StatefulWidget {
  const FinishTOButton({
    Key? key,
    required this.actId,
    required this.finishedAt,
    this.onFinished,
  }) : super(key: key);

  /// Акт выбранного месяца. Ноль означает, что месяц ещё не выбран.
  final int actId;

  /// Дата окончания из ответа сервера. Не `null` — ТО уже закрыто.
  final dynamic finishedAt;

  /// Позвать после успешного закрытия: экрану нужно перечитать график.
  final Future<void> Function()? onFinished;

  @override
  State<FinishTOButton> createState() => _FinishTOButtonState();
}

class _FinishTOButtonState extends State<FinishTOButton> {
  bool _sending = false;

  bool get _alreadyFinished {
    final dynamic value = widget.finishedAt;
    return value != null && '$value'.trim().isNotEmpty;
  }

  Future<void> _finish() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Завершить ТО?'),
            content: const Text(
              'Акт получит дату окончания и статус «Выполнено». '
              'Месяц зачтётся выполненным в статистике на главной.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Завершить',
                  style: TextStyle(color: ColorApp.myColorGreenAuth),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _sending = true);
    bool ok = false;
    try {
      ok = await finishFactAct(widget.actId);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _sending = false);

    // Молчаливая неудача здесь опаснее обычного: человек уверен, что ТО
    // закрыто, а в статистике месяц остаётся проваленным.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'ТО завершено' : 'Не удалось завершить ТО'),
        backgroundColor: ok ? ColorApp.myColorGreenAuth : ColorApp.myColorRed,
      ),
    );

    if (ok && widget.onFinished != null) {
      await widget.onFinished!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Месяц не выбран — кнопке нечего закрывать.
    if (widget.actId == 0) return const SizedBox.shrink();

    if (_alreadyFinished) {
      return Row(
        children: [
          const Icon(Icons.check_circle,
              color: ColorApp.myColorGreenAuth, size: 20.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'ТО завершено ${_formatDate(widget.finishedAt)}',
              style: const TextStyle(color: ColorApp.myColorGray),
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
      ),
      onPressed: _sending ? null : _finish,
      child: _sending
          ? const SizedBox(
              width: 18.0,
              height: 18.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white,
              ),
            )
          : const Text('Завершить ТО'),
    );
  }
}

/// Дата из ответа сервера в «дд.мм.гггг».
///
/// Разбор руками, а не `DateFormat`: данные русской локали в приложении нигде
/// не инициализируются явно, и форматирование даты падает уже в проде.
String _formatDate(dynamic value) {
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) return '';
  final String day = parsed.day.toString().padLeft(2, '0');
  final String month = parsed.month.toString().padLeft(2, '0');
  return '$day.$month.${parsed.year}';
}
