import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/in_progress_works_bloc.dart';
import 'in_progress_section.dart';

/// Как часто раздел перечитывает себя сам.
///
/// Минута — тот же такт, что и у времени в пилюле: раздел показывает работы,
/// которые идут прямо сейчас, и человек смотрит на него, чтобы решить, звонить
/// механику или подождать. Чаще — лишние запросы ради строки, которая всё
/// равно меняется раз в минуту; реже — прораб успевает принять решение по
/// картине, которой уже нет.
const Duration _period = Duration(minutes: 1);

/// Раздел «Сейчас в работе», который сам себя обновляет.
///
/// Кнопки «Повторить» у раздела нет намеренно: прораб держит этот экран
/// открытым фоном, и требовать от него нажатий ради свежих данных — значит
/// показывать вчерашнюю картину всякий раз, когда он забыл нажать. Опрос
/// делает это за него, а после сбоя раздел встаёт следующим тактом.
///
/// Таймер живёт здесь, а не в блоке: остановить его надо вместе с экраном, а
/// про экран знает виджет.
class InProgressWorksLive extends StatefulWidget {
  const InProgressWorksLive({Key? key}) : super(key: key);

  @override
  State<InProgressWorksLive> createState() => _InProgressWorksLiveState();
}

class _InProgressWorksLiveState extends State<InProgressWorksLive>
    with WidgetsBindingObserver {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Приложение свернули — опрос замолкает: запросы в фоне тратят батарею
  /// механика и трафик, а увидеть их результат некому. Вернулись — список
  /// перечитываем сразу, не дожидаясь такта: за время сна он устарел сильнее,
  /// чем на минуту.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _start();
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _start() {
    _tick?.cancel();
    _tick = Timer.periodic(_period, (Timer _) => _refresh());
  }

  void _refresh() {
    final InProgressWorksBloc bloc = context.read<InProgressWorksBloc>();
    // Запрос уже в пути — второй ни к чему. Зависнуть он не может: у
    // репозитория таймаут в 20 секунд, это короче такта.
    if (bloc.state is InProgressWorksLoading) return;
    bloc.add(const InProgressWorksRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InProgressWorksBloc, InProgressWorksState>(
      builder: (BuildContext context, InProgressWorksState state) =>
          InProgressSection(state: state),
    );
  }
}
