/// Значок дефектных актов, который сам ходит за числом.
///
/// Нужен там, где блока и репозитория рядом нет: в окне объекта прораба
/// (`object_foreman/object_page_foreman.dart`) экран унаследован от
/// подрядчика — один `build` на полторы тысячи строк и данные в `Map`. Заводить
/// ради счётчика блок на весь экран — это переписывать экран, а он не в этой
/// задаче. В окне «График объекта» число живёт в `ScheduleObjectBloc`, и там
/// берётся [DefectsBadge] напрямую.
///
/// Пока число не пришло и если запрос не удался — пусто. Значок появляется
/// только тогда, когда есть что показать: пустое место честнее серого
/// значка, обещающего «дефектов не было» вместо неотвеченного запроса.
library;

import 'package:flutter/material.dart';

import 'defects_badge.dart';
import 'defects_repository.dart';

class LiveDefectsBadge extends StatefulWidget {
  const LiveDefectsBadge({
    Key? key,
    required this.objectId,
    this.year,
    this.repository,
    this.onTap,
  }) : super(key: key);

  final int objectId;

  /// Год, за который считаем. По умолчанию текущий — в окне объекта
  /// переключателя года нет.
  final int? year;

  /// Подменяется в тестах. По умолчанию — живой репозиторий.
  final DefectsRepository? repository;

  /// Что делать по нажатию. Пусто — значок только показывает число, а нажатие
  /// достаётся тому, кто под ним: в окне объекта вся строка «Дефекты объекта»
  /// и так открывает список.
  final VoidCallback? onTap;

  @override
  State<LiveDefectsBadge> createState() => _LiveDefectsBadgeState();
}

class _LiveDefectsBadgeState extends State<LiveDefectsBadge> {
  late final int _year;
  int? _count;

  @override
  void initState() {
    super.initState();
    _year = widget.year ?? DateTime.now().year;
    _load();
  }

  Future<void> _load() async {
    final DefectsRepository repository =
        widget.repository ?? const DefectsRepository();
    try {
      final int count = await repository.countByObjectAndYear(
        objectId: widget.objectId,
        year: _year,
      );
      if (!mounted) return;
      setState(() => _count = count);
    } catch (_) {
      // Молча: счётчик — не главное в окне объекта, и плашку об ошибке он не
      // заслуживает.
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? count = _count;
    if (count == null) return const SizedBox.shrink();
    return DefectsBadge(count: count, year: _year, onTap: widget.onTap);
  }
}
