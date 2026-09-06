/// Блок «Дефекты» в карточке работы по ТО вместе с запросом за ними.
///
/// Своим состоянием, а не блоком карточки: `WorkDetailsBloc` знает работу и
/// её снимки, дефекты же приезжают другой ручкой и другому экрану не нужны —
/// расширять его ради одной строки значило бы тащить дефекты в карточки
/// идущих и сданных работ, где блока нет. Тот же приём, что у
/// [LiveDefectsBadge] (`live_defects_badge.dart`).
///
/// Отличие от значка: **отказ запроса здесь не молчит**. Значок при неудаче
/// пропадает — пустое место честнее серого нуля. Блок обещан всегда, и
/// исчезнув, он сказал бы «дефектов нет» вместо «спросить не вышло».
library;

import 'package:flutter/material.dart';

import 'defect_card_screen.dart';
import 'defect_entry.dart';
import 'defects_repository.dart';
import 'work_defects_block.dart';

class WorkDefectsSection extends StatefulWidget {
  const WorkDefectsSection({
    Key? key,
    required this.workId,
    this.objectName,
    this.repository,
    this.entries,
  }) : super(key: key);

  /// Работа по ТО — она же `act_fact` на бэкенде.
  final int workId;

  /// Имя объекта: карточка акта берёт его снаружи, в самом акте его нет.
  final String? objectName;

  /// Подменяется в тестах. По умолчанию — живой репозиторий.
  final DefectsRepository? repository;

  /// Готовый список: набросок и тесты вёрстки в сеть не ходят.
  final List<DefectEntry>? entries;

  @override
  State<WorkDefectsSection> createState() => _WorkDefectsSectionState();
}

class _WorkDefectsSectionState extends State<WorkDefectsSection> {
  late List<DefectEntry> _entries;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries ?? const <DefectEntry>[];
    if (widget.entries == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final DefectsRepository repository =
        widget.repository ?? const DefectsRepository();
    try {
      final List<DefectEntry> entries =
          await repository.byActFact(widget.workId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _open(DefectEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DefectCardScreen(
          entry: entry,
          objectName: widget.objectName,
          repository: widget.repository,
          // Описание и снимки в строку блока не приезжают — карточка
          // дозапрашивает их сама, как и из ленты объекта.
          loadFull: widget.entries == null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorkDefectsBlock(
      entries: _entries,
      loading: _loading,
      failure: _error,
      onRetry: _load,
      onTap: _open,
    );
  }
}
