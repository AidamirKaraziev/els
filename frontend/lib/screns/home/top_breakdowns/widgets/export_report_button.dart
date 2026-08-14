import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helper/class_colors.dart';
import '../repository/breakdowns_repository.dart';

/// Кнопка «Скачать PDF» на экране подробностей топа поломок.
///
/// Файл собирает сервер тем же кодом, что считает отчёт на экране, — иначе
/// цифры в отправленном заказчику файле однажды разошлись бы с виджетом.
///
/// Прямо к ручке выгрузки обратиться нельзя: ей нужен заголовок
/// `Authorization`, а новая вкладка его не отправит. Поэтому сначала
/// спрашиваем у сервера короткоживущую ссылку и открываем уже её.
class ExportReportButton extends StatefulWidget {
  const ExportReportButton({
    Key? key,
    required this.month,
    this.divisionId,
    this.organizationId,
    this.repository = const BreakdownsRepository(),
  }) : super(key: key);

  /// Тот же период и тот же отбор, что на экране: файл обязан совпадать с
  /// тем, что человек видит.
  final DateTime month;
  final int? divisionId;
  final int? organizationId;
  final BreakdownsRepository repository;

  @override
  State<ExportReportButton> createState() => _ExportReportButtonState();
}

class _ExportReportButtonState extends State<ExportReportButton> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final String url = await widget.repository.exportLink(
        year: widget.month.year,
        month: widget.month.month,
        divisionId: widget.divisionId,
        organizationId: widget.organizationId,
      );
      if (!mounted) return;
      // Ссылка живёт минуту, поэтому открываем сразу после получения, а не
      // складываем в состояние.
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on BreakdownsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _download,
      icon: _busy
          ? const SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : const Icon(Icons.file_download_outlined, size: 18.0),
      label: Text(_busy ? 'Готовим файл' : 'Скачать PDF'),
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
