import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Кнопка «Скачать PDF» на экране подробностей.
///
/// Пока только кнопка. Ручка выгрузки на бэкенде готова
/// (`GET /api/v1/statistics/breakdowns/export`), но ей нужен заголовок
/// `Authorization`, поэтому просто открыть адрес в новой вкладке нельзя —
/// придёт 403. Способ скачивания выбирается отдельно, см.
/// `BreakdownsRepository.exportUrl`.
///
/// Кнопка не выключена намеренно: серая кнопка без объяснения читается как
/// поломка. Нажатие честно говорит, что выгрузки пока нет.
class ExportReportButton extends StatelessWidget {
  const ExportReportButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выгрузка в PDF ещё не подключена'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.file_download_outlined, size: 18.0),
      label: const Text('Скачать PDF'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorApp.myColorGreenAuth,
        side: const BorderSide(color: ColorApp.myColorGreenAuth),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
