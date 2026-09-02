import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../helper/class_colors.dart';
import '../bloc/schedule_wizard_bloc.dart';
import '../models/maintenance_program.dart';
import '../models/schedule_wizard_data.dart';
import '../repository/maintenance_program_repository.dart';
import '../repository/schedule_wizard_repository.dart';
import '../widgets/wizard_anchor_step.dart';
import '../widgets/wizard_preview_step.dart';
import '../widgets/wizard_program_dialog.dart';
import '../widgets/wizard_steps_header.dart';

/// Мастер расстановки годового графика — два шага вместо кнопки, которая
/// раскладывала весь год одним нажатием.
///
/// Заготовку строит сервер: `GET /planned-to/preview/` отдаёт двенадцать
/// клеток года по программе модели, ничего не записывая. Мастер её только
/// показывает — своей арифметики цикла здесь нет.
///
/// «Утвердить» расставляет год сам — `POST /planned-to/generate/` с тем
/// месяцем начала цикла, который человек видел в предпросмотре. Мастер
/// закрывается с `true`, а экран объекта по нему только перечитывает ленту
/// года: создаёт график ровно один запрос.
///
/// Кадра на мастер нет: рисовали сами, в стиле принятых блоков экрана
/// объекта — те же карточки `objectCardDecoration()` и та же палитра.
class ScheduleWizardScreen extends StatelessWidget {
  const ScheduleWizardScreen({
    Key? key,
    required this.repository,
    required this.programRepository,
    required this.objectId,
    required this.year,
    this.modelId,
    this.modelName,
    this.objectName,
  }) : super(key: key);

  /// Откуда берётся заготовка. Обязателен: под ним стоит либо фикстура, либо
  /// сеть, и умолчания у него быть не должно.
  final ScheduleWizardRepository repository;

  /// Откуда берётся программа модели и куда уходит её правка. Отдельно от
  /// [repository] по той же границе, что и в самих репозиториях: заготовка —
  /// про год объекта, программа — про модель.
  final MaintenanceProgramRepository programRepository;

  final int objectId;

  /// Год, на который расставляется график.
  final int year;

  /// Модель оборудования объекта. `null` — в карточке её нет: правка
  /// программы тогда недоступна, и строка программы об этом говорит.
  final int? modelId;

  /// Марка с моделью словами — начало названия программы в окне правки.
  final String? modelName;

  /// Название объекта для шапки — то же, что в шапке экрана графика.
  final String? objectName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleWizardBloc>(
      create: (_) => ScheduleWizardBloc(
        repository: repository,
        programRepository: programRepository,
        objectId: objectId,
        year: year,
      )..add(const WizardOpened()),
      child: _WizardView(
        year: year,
        objectName: objectName,
        programRepository: programRepository,
        modelId: modelId,
        modelName: modelName,
      ),
    );
  }
}

/// Шаги мастера поверх готового состояния.
///
/// Номер шага живёт здесь, а не в блоке: это перелистывание уже загруженного,
/// без запросов и без ошибок. Якорь, наоборот, в блоке — от него зависит
/// запрос к серверу.
class _WizardView extends StatefulWidget {
  const _WizardView({
    Key? key,
    required this.year,
    required this.programRepository,
    this.modelId,
    this.modelName,
    this.objectName,
  }) : super(key: key);

  final int year;
  final MaintenanceProgramRepository programRepository;
  final int? modelId;
  final String? modelName;
  final String? objectName;

  @override
  State<_WizardView> createState() => _WizardViewState();
}

class _WizardViewState extends State<_WizardView> {
  /// Индекс текущего шага в списке заголовков, с нуля.
  int _step = 0;

  List<String> _titles(bool hasAnchorStep) => <String>[
        if (hasAnchorStep) 'Точка отсчёта',
        'Предпросмотр',
      ];

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

  void _next(int last) {
    if (_step >= last) return;
    setState(() => _step++);
  }

  void _approve() {
    // Закрываемся не здесь, а по ответу сервера: пока идёт запись, мастер
    // остаётся на экране с погашенными кнопками, а неудача показывается
    // прямо в нём — закрыв его раньше времени, показать её было бы негде.
    context.read<ScheduleWizardBloc>().add(const WizardApproved());
  }

  /// Открыть окно правки программы и, если человек сохранил, отдать её блоку.
  ///
  /// Сохраняет не окно, а блок: за `PUT` идёт перезапрос заготовки года, и
  /// окну, которое к этому моменту уже закрыто, показывать неудачу негде.
  Future<void> _editProgram(ScheduleWizardLoaded state) async {
    final ScheduleWizardBloc bloc = context.read<ScheduleWizardBloc>();
    final MaintenanceProgram? saved = await showWizardProgramDialog(
      context,
      repository: widget.programRepository,
      modelId: widget.modelId!,
      // Марка с моделью: из карточки объекта, а без неё — из заготовки. У
      // модели без программы заготовки нет вовсе, потому карточка первая.
      modelName: widget.modelName ?? state.data?.modelName ?? '',
    );
    if (saved == null) return;
    bloc.add(WizardProgramSaved(saved));
  }

  Widget _body(ScheduleWizardLoaded state) {
    final String title = _titles(state.hasAnchorStep)[_step];
    if (title == 'Точка отсчёта') {
      // Шаг есть только при живой заготовке: `hasAnchorStep` без неё ложен.
      return WizardAnchorStep(
        data: state.data!,
        anchorMonth: state.anchorMonth,
        onChanged: (int month) => context
            .read<ScheduleWizardBloc>()
            .add(WizardAnchorChanged(month)),
      );
    }
    return WizardPreviewStep(
      data: state.data,
      anchorMonth: state.anchorMonth,
      // Модели нет — править нечего: строка программы гасит кнопку и говорит
      // почему. Идти в окно с выдуманным `modelId` было бы хуже.
      onEditProgram: widget.modelId == null ? null : () => _editProgram(state),
      // Перетаскивание — тот же выбор точки отсчёта, только по любой клетке.
      // На время перезапроса лента замирает: две правки подряд разошлись бы
      // с тем, что считает сервер.
      onAnchorMoved: state.data == null || state.isReloading
          ? null
          : (int month) => context
              .read<ScheduleWizardBloc>()
              .add(WizardAnchorChanged(month)),
    );
  }

  /// Почему «Утвердить» не нажимается. `null` — кнопка выключена не по вине
  /// заготовки, а на время перезапроса: объяснять мгновенную паузу нечем.
  String? _disabledReason(ScheduleWizardLoaded state) {
    final ScheduleWizardData? data = state.data;
    if (data == null) {
      return 'Сначала создайте программу модели — по ней раскладывается год';
    }
    if (data.hasMissingTemplate) {
      return 'Сначала заведите шаблон чек-листа на отмеченные виды ТО';
    }
    if (data.hasNothingToAdd) {
      return 'Все месяцы этого года уже расставлены — добавлять нечего';
    }
    return null;
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
          'График на ${widget.year}',
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
      body: BlocConsumer<ScheduleWizardBloc, ScheduleWizardState>(
        listener: (BuildContext context, ScheduleWizardState state) {
          // График создан — возвращаем `true`: по нему экран объекта
          // перечитывает ленту года.
          if (state is ScheduleWizardApproved) Navigator.of(context).pop(true);
        },
        builder: (BuildContext context, ScheduleWizardState state) {
          if (state is ScheduleWizardFailure) {
            return _Failure(
              message: state.message,
              onRetry: () =>
                  context.read<ScheduleWizardBloc>().add(const WizardOpened()),
              onClose: () => Navigator.of(context).pop(false),
            );
          }
          if (state is! ScheduleWizardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<String> titles = _titles(state.hasAnchorStep);
          // Шаг мог остаться за концом списка: с прошлогодним графиком шаг
          // один, без него — два, и после перезапроса список короче.
          final int step = _step >= titles.length ? titles.length - 1 : _step;
          final bool isLast = step == titles.length - 1;

          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      WizardStepsHeader(titles: titles, current: step),
                      const SizedBox(height: 24.0),
                      if (state.error != null) ...<Widget>[
                        _ErrorNote(message: state.error!),
                        const SizedBox(height: 16.0),
                      ],
                      _body(state),
                    ],
                  ),
                ),
              ),
              _Bottom(
                isLast: isLast,
                isFirst: step == 0,
                // «Утвердить» гаснет, пока у модели нет программы, пока в
                // предпросмотре есть клетка «нет шаблона», когда добавлять
                // нечего, и на время перезапроса: утверждать заготовку,
                // которая сейчас сменится, нечего.
                canApprove: state.canApprove && !state.isReloading,
                disabledReason: _disabledReason(state),
                isApproving: state.isApproving,
                onBack: _back,
                onNext: () => _next(titles.length - 1),
                onApprove: _approve,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Заготовку построить не удалось: показываем причину словами и два выхода.
class _Failure extends StatelessWidget {
  const _Failure({
    Key? key,
    required this.message,
    required this.onRetry,
    required this.onClose,
  }) : super(key: key);

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.0, color: ColorApp.myColorBlack),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: ColorApp.myColorGray,
                  ),
                  child: const Text('Закрыть'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: onRetry,
                  style: _Bottom._primaryStyle(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Неудача перезапроса при живой заготовке — плашкой над шагами.
///
/// Не всплывающей: человек только что сменил месяц и должен понять, что
/// лента осталась прежней, а за три секунды `SnackBar` он этого не успеет.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorYellowLight,
        border: Border.all(color: ColorApp.myColorYellow),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
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
    this.disabledReason,
    this.isApproving = false,
    required this.onBack,
    required this.onNext,
    required this.onApprove,
  }) : super(key: key);

  final bool isLast;
  final bool isFirst;
  final bool canApprove;

  /// Почему «Утвердить» не нажимается — текст тултипа. `null`, когда кнопка
  /// выключена не по вине заготовки, а на время перезапроса: объяснять
  /// мгновенную паузу нечем.
  final String? disabledReason;

  /// Идёт создание графика: обе кнопки выключены, на правой крутилка. Уйти
  /// назад посреди записи нельзя — запрос уже ушёл.
  final bool isApproving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    Widget primary = ElevatedButton(
      onPressed: isApproving
          ? null
          : (isLast ? (canApprove ? onApprove : null) : onNext),
      style: _primaryStyle(),
      child: isApproving
          ? const SizedBox(
              width: 18.0,
              height: 18.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor:
                    AlwaysStoppedAnimation<Color>(ColorApp.myColorWhite),
              ),
            )
          : Text(isLast ? 'Утвердить' : 'Далее'),
    );
    if (isLast && !canApprove && !isApproving && disabledReason != null) {
      // Выключенная кнопка обязана объяснять себя: почему она серая, иначе
      // написано только в примечании под клетками. Обёртка только на
      // выключенной: с пустым текстом тултип всплывает пустой рамкой.
      primary = Tooltip(message: disabledReason!, child: primary);
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
              onPressed: isApproving ? null : onBack,
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
