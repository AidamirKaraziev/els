import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Поиск по лупе над лентой графиков.
///
/// Лупа разворачивает поле, крестик очищает и сворачивает. Свёрнутое поле —
/// требование кадра `83:312`: в ряду с пятью фильтрами и годом развёрнутому
/// полю места нет.
///
/// Запрос уходит **через паузу в 300 мс** после последней буквы, а не на каждое
/// нажатие: «Карнавал» — это восемь запросов к серверу, из которых нужен один,
/// и семь промежуточных ответов, приходящих вразнобой.
class ScheduleSearchField extends StatefulWidget {
  const ScheduleSearchField({
    Key? key,
    required this.text,
    required this.onSearch,
  }) : super(key: key);

  /// Текущий текст поиска из отбора. Поле открыто, если он не пуст: так поиск
  /// переживает перерисовку панели после ответа сервера.
  final String text;

  final ValueChanged<String> onSearch;

  /// Пауза, после которой запрос уходит.
  static const Duration debounce = Duration(milliseconds: 300);

  @override
  State<ScheduleSearchField> createState() => _ScheduleSearchFieldState();
}

class _ScheduleSearchFieldState extends State<ScheduleSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.text;
    _open = widget.text.isNotEmpty;
  }

  /// Отбор сбросили снаружи — «Сбросить всё» — и поле должно опустеть вместе с
  /// ним. Без этого крестик у соседней пилюли оставлял бы в лупе слово, которое
  /// уже не участвует в запросе.
  @override
  void didUpdateWidget(covariant ScheduleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != _controller.text) {
      _controller.text = widget.text;
      // Поле, открытое человеком, само не закрывается: опустело — значит, в
      // нём снова можно набирать, а не значит, что его пора убрать.
      if (widget.text.isNotEmpty) _open = true;
    }
  }

  @override
  void dispose() {
    // Таймер живёт дольше виджета, если его не убить: сработав после ухода с
    // экрана, он дёрнет уже отсоединённый блок.
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(ScheduleSearchField.debounce, () => widget.onSearch(value));
  }

  /// Крестик очищает и закрывает поле.
  ///
  /// Отложенный запрос при этом отменяется: иначе набранное и тут же стёртое
  /// слово успело бы уехать на сервер вдогонку.
  void _close() {
    _timer?.cancel();
    _controller.clear();
    setState(() => _open = false);
    if (widget.text.isNotEmpty) widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return Tooltip(
        message: 'Поиск',
        child: InkWell(
          onTap: () => setState(() => _open = true),
          child: Container(
            width: 28,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ColorApp.myColorGreenAuth),
            ),
            child: const Icon(
              Icons.search,
              size: 14,
              color: ColorApp.myColorGreenAuth,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 24,
      child: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: _onChanged,
        cursorColor: ColorApp.myColorGray,
        style: const TextStyle(fontSize: 10, color: ColorApp.myColorBlack),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          hintText: 'Объект, номер, адрес, участок, тип, ТО',
          hintStyle: const TextStyle(
            fontSize: 10,
            color: ColorApp.myColorGrayText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 14,
            color: ColorApp.myColorGreenAuth,
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: Tooltip(
            message: 'Закрыть поиск',
            child: InkWell(
              onTap: _close,
              child: const Icon(
                Icons.close,
                size: 12,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 24, minHeight: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: ColorApp.myColorGreenAuth),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: ColorApp.myColorGreenAuth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: const BorderSide(color: ColorApp.myColorGreenAuth),
          ),
        ),
      ),
    );
  }
}
