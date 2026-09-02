import 'package:flutter/material.dart';

import '../../../../../helper/class_colors.dart';
import '../models/schedule_wizard_data.dart';
import '../widgets/wizard_anchor_step.dart';
import '../widgets/wizard_preview_step.dart';
import '../widgets/wizard_program_step.dart';
import '../widgets/wizard_steps_header.dart';

/// Мастер расстановки годового графика — три шага вместо кнопки, которая
/// раскладывала весь год одним нажатием.
///
/// **Пока набросок.** Данные приходят готовыми ([data]), сети здесь нет:
/// внешний вид утверждается до логики (правило репозитория). Следующей
/// работой [data] заполнится из `GET /planned-to/preview/`, а «Утвердить»
/// позовёт `POST /planned-to/` — формы моделей под это уже подогнаны.
///
/// Кадра на мастер нет: рисовали сами, в стиле принятых блоков экрана
/// объекта — те же карточки `objectCardDecoration()` и та же палитра.
///
/// Шаг держится в `setState`, а не в блоке: у наброска нет ни загрузки, ни
/// ошибок, и блок здесь был бы обёрткой вокруг одного числа.
class ScheduleWizardScreen extends StatefulWidget {
  const ScheduleWizardScreen({
    Key? key,
    required this.data,
    this.objectName,
  }) : super(key: key);

  final ScheduleWizardData data;

  /// Название объекта для шапки — то же, что в шапке экрана графика.
  final String? objectName;

  @override
  State<ScheduleWizardScreen> createState() => _ScheduleWizardScreenState();
}

class _ScheduleWizardScreenState extends State<ScheduleWizardScreen> {
  /// Индекс текущего шага в [_titles], с нуля.
  int _step = 0;

  /// Месяц начала цикла. С прошлогодним графиком он известен и не
  /// спрашивается; без него человек выбирает на шаге 2, а до выбора стоит
  /// январь — видимое умолчание, а не молча применённый сдвиг.
  late int _anchorMonth = widget.data.previousYearAnchor ?? 1;

  /// Шаг «Точка отсчёта» отпадает, когда цикл продолжается с прошлого года.
  bool get _hasAnchorStep => !widget.data.hasPreviousYear;

  List<String> get _titles => <String>[
        'Программа модели',
        if (_hasAnchorStep) 'Точка отсчёта',
        'Предпросмотр',
      ];

  bool get _isLast => _step == _titles.length - 1;

  /// «Утвердить» гаснет, пока в предпросмотре есть клетка «нет шаблона».
  bool get _canApprove => !widget.data.hasMissingTemplate;

  void _next() {
    if (_isLast) return;
    setState(() => _step++);
  }

  /// «Назад» с первого шага закрывает мастер: отдельной кнопки «Отмена» в
  /// нижней панели нет, а уходить из мастера человек должен уметь тем же
  /// движением, каким он по нему шёл.
  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _step--);
  }

  void _approve() {
    if (!_canApprove) return;
    // Набросок ничего не создаёт сам: экран графика на `true` шлёт то же
    // событие, что раньше слала кнопка. Выбранный месяц пока никуда не
    // уходит — его заберёт `preview`/`generate` следующей работой.
    Navigator.of(context).pop(true);
  }

  Widget _body() {
    final String title = _titles[_step];
    if (title == 'Программа модели') {
      return WizardProgramStep(data: widget.data);
    }
    if (title == 'Точка отсчёта') {
      return WizardAnchorStep(
        data: widget.data,
        anchorMonth: _anchorMonth,
        onChanged: (int month) => setState(() => _anchorMonth = month),
      );
    }
    return WizardPreviewStep(data: widget.data, anchorMonth: _anchorMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: Text(
          'График на ${widget.data.year}',
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: ColorApp.myColorBlack,
          ),
        ),
        // Название объекта — второй строкой: в шапке уже стоит год, и класть
        // их в одну строку значит получить обрезанное и то, и другое.
        bottom: widget.objectName == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                    child: Text(
                      widget.objectName!,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: ColorApp.myColorGray,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ColorApp.kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WizardStepsHeader(titles: _titles, current: _step),
                  const SizedBox(height: 24.0),
                  _body(),
                ],
              ),
            ),
          ),
          _Bottom(
            isLast: _isLast,
            isFirst: _step == 0,
            canApprove: _canApprove,
            onBack: _back,
            onNext: _next,
            onApprove: _approve,
          ),
        ],
      ),
    );
  }
}

/// Нижняя панель: «Назад» слева, «Далее» или «Утвердить» справа.
class _Bottom extends StatelessWidget {
  const _Bottom({
    Key? key,
    required this.isLast,
    required this.isFirst,
    required this.canApprove,
    required this.onBack,
    required this.onNext,
    required this.onApprove,
  }) : super(key: key);

  final bool isLast;
  final bool isFirst;
  final bool canApprove;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    Widget primary = ElevatedButton(
      onPressed: isLast ? (canApprove ? onApprove : null) : onNext,
      style: _primaryStyle(),
      child: Text(isLast ? 'Утвердить' : 'Далее'),
    );
    if (isLast && !canApprove) {
      // Выключенная кнопка обязана объяснять себя: почему она серая, иначе
      // написано только в примечании под клетками. Обёртка только на
      // выключенной: с пустым текстом тултип всплывает пустой рамкой.
      primary = Tooltip(
        message: 'Сначала заведите шаблон чек-листа на отмеченные виды ТО',
        child: primary,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: ColorApp.myColorWhite,
        border: Border(top: BorderSide(color: ColorApp.myColorGrayBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorGray,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
              ),
              child: Text(isFirst ? 'Отмена' : 'Назад'),
            ),
            const Spacer(),
            primary,
          ],
        ),
      ),
    );
  }

  static ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      );
}
