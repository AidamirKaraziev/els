import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/work_details_bloc.dart';

/// Как часто карточка перечитывает работу.
///
/// Тот же такт, что и у раздела (`in_progress_works_live.dart`), и это не
/// совпадение: карточка открыта поверх раздела, и расходиться в свежести им
/// нельзя — прораб вернётся к списку и увидит другое.
const Duration _period = Duration(minutes: 1);

/// Карточка работы, которая сама себя обновляет.
///
/// Работа под карточкой продолжается, пока её читают: механик отмечает пункты,
/// снимает паузу, закрывает работу. Карточка, загруженная один раз, к третьей
/// минуте начинает врать — а прораб по ней решает, звонить или ехать.
///
/// Таймер живёт здесь, а не в блоке: остановить его надо вместе с экраном, а
/// про экран знает виджет. Так же устроен раздел.
class WorkCardLive extends StatefulWidget {
  const WorkCardLive({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<WorkCardLive> createState() => _WorkCardLiveState();
}

class _WorkCardLiveState extends State<WorkCardLive>
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

  /// Приложение свернули — такт замолкает: запросы в фоне тратят батарею и
  /// трафик, а смотреть на их результат некому. Вернулись — перечитываем
  /// сразу: за время сна карточка устарела сильнее, чем на минуту.
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
    final WorkDetailsBloc bloc = context.read<WorkDetailsBloc>();
    final WorkDetailsState state = bloc.state;

    // Работы больше нет — спрашивать про неё нечего. Состояние конечное:
    // сданная работа обратно в работу не возвращается, и такт можно погасить
    // совсем.
    if (state is WorkGone) {
      _tick?.cancel();
      _tick = null;
      return;
    }

    // Первая загрузка ещё в пути — второй запрос ни к чему. Зависнуть она не
    // может: у репозитория таймаут в 20 секунд, это короче такта.
    if (state is WorkDetailsLoading) return;

    bloc.add(const WorkDetailsRefreshed());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
