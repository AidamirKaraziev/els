/// Дефекты объекта за год — список у прораба.
///
/// Зачем экран: механик заводит дефект из четырёх мест, но до этого этапа
/// увидеть заведённое было негде. Прораб — первый, кто их читает.
///
/// Кадра в макете нет, вёрстка собрана из приёмов карточки объекта прораба и
/// списков механика (см. `defects_layout.dart`). Появится кадр — сверять надо
/// этот файл и `defect_card_screen.dart`.
///
/// Год обязателен: ручка `GET /defective-act/by-object/{id}/` без него не
/// отвечает, и лента режется по **дате создания** акта, а не по году плана.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import 'defect_card_screen.dart';
import 'defect_entry.dart';
import 'defects_layout.dart';
import 'defects_repository.dart';

class DefectsScreen extends StatefulWidget {
  const DefectsScreen({
    Key? key,
    required this.objectId,
    this.objectName,
    this.entries,
    this.repository,
    this.today,
    this.initialYear,
  }) : super(key: key);

  final int objectId;
  final String? objectName;

  /// Год, с которого открывается список. Задаётся, когда экран открыт со
  /// значка-счётчика: значок посчитан за показанный год, и список обязан
  /// открыться на том же — иначе число и лента расходятся.
  final int? initialYear;

  /// Готовый список — для набросков и тестов. В приложении не задаётся:
  /// экран спрашивает сервер сам.
  final List<DefectEntry>? entries;

  /// Подменяется в тестах. По умолчанию — живой репозиторий.
  final DefectsRepository? repository;

  /// Сегодняшний день. Задаётся в тестах, чтобы год не зависел от календаря
  /// машины, на которой их гоняют.
  final DateTime? today;

  @override
  State<DefectsScreen> createState() => _DefectsScreenState();
}

class _DefectsScreenState extends State<DefectsScreen> {
  late int _year;
  late DefectsRepository _repository;

  List<DefectEntry> _entries = const <DefectEntry>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear ?? (widget.today ?? DateTime.now()).year;
    _repository = widget.repository ?? const DefectsRepository();
    _load();
  }

  Future<void> _load() async {
    // Набросок живёт на готовом списке: сети у него нет вовсе. Год всё равно
    // отрабатывает — иначе переключатель в наброске нечем показать, а пустой
    // год нечем посмотреть. На живых данных по году режет сервер.
    if (widget.entries != null) {
      setState(() {
        _entries = widget.entries!
            .where((DefectEntry entry) => entry.createdAt?.year == _year)
            .toList();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DefectEntry> entries = await _repository.byObjectAndYear(
        objectId: widget.objectId,
        year: _year,
      );
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

  void _changeYear(int delta) {
    setState(() => _year += delta);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              objectName: widget.objectName,
              year: _year,
              onPrevious: () => _changeYear(-1),
              onNext: () => _changeYear(1),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Failed(message: _error!, onRetry: _load);
    }
    if (_entries.isEmpty) {
      return _Empty(year: _year);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 4.0,
          bottom: 32.0,
        ),
        itemCount: _entries.length,
        itemBuilder: (BuildContext context, int index) {
          final DefectEntry entry = _entries[index];
          return _DefectCard(
            entry: entry,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DefectCardScreen(
                  entry: entry,
                  objectName: widget.objectName,
                  repository: widget.repository,
                  // Набросок и тесты работают на готовом списке: дозагружать
                  // им нечего и негде.
                  loadFull: widget.entries == null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Шапка: назад, название объекта и переключатель года.
///
/// Переключатель именно стрелками, как в окне графика объекта: год почти
/// всегда текущий, а выпадающий список ради одного шага назад — лишний клик.
class _Header extends StatelessWidget {
  const _Header({
    required this.objectName,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
  });

  final String? objectName;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.myColorWhite,
      padding: const EdgeInsets.fromLTRB(
        DefectsLayout.screenPadding,
        14.0,
        DefectsLayout.screenPadding,
        14.0,
      ),
      child: Row(
        children: <Widget>[
          _SquareButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Дефекты', style: DefectsLayout.screenTitle),
                if (objectName != null) ...<Widget>[
                  const SizedBox(height: 3.0),
                  Text(
                    objectName!,
                    style: DefectsLayout.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          _SquareButton(icon: Icons.chevron_left, onTap: onPrevious),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text('$year', style: DefectsLayout.yearValue),
          ),
          _SquareButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
      child: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
          border: Border.all(color: ColorApp.myColorGrayBorder, width: 1.0),
          color: ColorApp.myColorWhite,
        ),
        child: Icon(icon, size: 15.0, color: ColorApp.myColorBlack),
      ),
    );
  }
}

/// Строка списка: заголовок, дата, откуда заведён, вид ТО, кто нашёл,
/// пилюля состояния.
class _DefectCard extends StatelessWidget {
  const _DefectCard({required this.entry, required this.onTap});

  final DefectEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DefectsLayout.screenPadding,
        DefectsLayout.cardGap,
        DefectsLayout.screenPadding,
        0.0,
      ),
      child: Material(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.title,
                        style: DefectsLayout.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    DefectStatePill(state: entry.state),
                  ],
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 4.0,
                  children: <Widget>[
                    if (entry.createdAt != null)
                      _Fact(
                        icon: Icons.event_outlined,
                        text: _formatDate(entry.createdAt!),
                      ),
                    _Fact(
                      icon: Icons.my_location_outlined,
                      text: entry.source.label,
                    ),
                    if (entry.typeActName != null)
                      _Fact(
                        icon: Icons.build_outlined,
                        text: entry.typeActName!,
                      ),
                    if (entry.monthName != null)
                      _Fact(
                        icon: Icons.calendar_month_outlined,
                        text: entry.monthName!,
                      ),
                    if (entry.authorName != null)
                      _Fact(
                        icon: Icons.person_outline,
                        text: entry.authorName!,
                      ),
                    if (entry.photos.isNotEmpty)
                      _Fact(
                        icon: Icons.photo_outlined,
                        text: '${entry.photos.length}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Значок с подписью — одна короткая справка в строке карточки.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14.0, color: ColorApp.myColorGrayText),
        const SizedBox(width: 5.0),
        Text(text, style: DefectsLayout.cardSubtitle),
      ],
    );
  }
}

/// Пустой год объясняется словами: пустой экран прораб прочитал бы как
/// поломку, а дело обычно в том, что дефектов за этот год просто не заводили.
class _Empty extends StatelessWidget {
  const _Empty({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.fact_check_outlined,
            size: 48.0,
            color: ColorApp.myColorGray,
          ),
          const SizedBox(height: 16.0),
          Text(
            'За $year год дефектов по объекту не заводили. Проверьте соседний '
            'год стрелками наверху.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.0,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Сорвавшийся запрос — это не «дефектов нет»: показываем прямо и даём повтор.
class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_outlined,
            size: 48.0,
            color: ColorApp.myColorGray,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Не удалось получить список дефектов.\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.0,
              color: ColorApp.myColorGray,
            ),
          ),
          const SizedBox(height: 16.0),
          OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
