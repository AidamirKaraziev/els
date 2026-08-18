/// Вкладка, экран которой делается следующим этапом.
///
/// Заголовок и поля — уже по макету: заявки (`1826:155`), объекты
/// (`1826:210`) и уведомления (`1826:270`) отличаются от готового экрана
/// только содержимым списка, и когда оно появится, шапка останется той же.
///
/// Заглушка честная: она говорит, чего ещё нет, и показывает, сколько
/// записей телефон уже держит у себя. Пустой экран без объяснения механик
/// прочитал бы как «приложение сломалось».
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/local_store.dart';
import '../data/mechanic_workspace.dart';
import '../mechanic_theme.dart';

class MechanicSoonScreen extends StatelessWidget {
  const MechanicSoonScreen({
    Key? key,
    required this.title,
    required this.note,
    this.collection,
  }) : super(key: key);

  final String title;

  /// Что здесь появится — словами для человека, а не «в разработке».
  final String note;

  /// Коллекция локальной базы, число записей которой стоит показать.
  final String? collection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MechanicLayout.screenPadding,
            24.0,
            MechanicLayout.screenPadding,
            16.0,
          ),
          child: Text(title, style: MechanicLayout.screenTitle),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.build_outlined,
                    size: 48.0,
                    color: ColorApp.myColorGreen,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    note,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: ColorApp.myColorGray,
                    ),
                  ),
                  if (collection != null) ...<Widget>[
                    const SizedBox(height: 12.0),
                    _StoredCount(collection: collection!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Сколько записей уже лежит на телефоне.
///
/// Это не украшение: до появления списков это единственное место, по
/// которому видно, что офлайн-база наполняется, а синхронизация работает.
class _StoredCount extends StatelessWidget {
  const _StoredCount({required this.collection});

  final String collection;

  @override
  Widget build(BuildContext context) {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    if (workspace == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: workspace.localStore.read(collection),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
      ) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final int count = snapshot.data!.length;
        final String what =
            collection == LocalCollection.orders ? 'заявок' : 'плановых ТО';
        return Text(
          'Загружено с сервера: $count $what',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGrayText),
        );
      },
    );
  }
}
