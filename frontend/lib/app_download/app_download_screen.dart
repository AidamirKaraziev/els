/// «Скачать приложение» — страница выдачи APK механикам.
///
/// Кадра в Figma на этот экран нет: раздача APK появилась после того, как
/// макет рисовали. Набросок утверждён отдельно, до написания логики — по
/// правилу репозитория.
///
/// Два состояния одного экрана:
///
/// * **в браузере** — приложения на телефоне ещё нет, показываем версию,
///   кнопку и инструкцию по установке;
/// * **внутри установленного приложения** — сравниваем свою версию с
///   серверной и зовём обновиться, только если серверная больше.
///
/// Своя версия приезжает из `--dart-define=APP_VERSION_CODE`, которую CI
/// подставляет при сборке APK. В веб-сборке её нет, поэтому там второе
/// состояние не наступает никогда — и правильно: в браузере обновлять нечего.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helper/class_colors.dart';
import '../mechanic/mechanic_theme.dart';
import 'app_release.dart';

/// Открыта ли система по короткому адресу `els23.ru/app`.
///
/// Маршрутизации в приложении нет — только `home:` и `Navigator.push`, —
/// поэтому адрес разбирается вручную. Спрашивают об этом двое: `main.dart`
/// при запуске (человек уже вошёл) и экран входа после успешного логина
/// (человек только что вошёл). Признак один на обоих: разъедься они, и по
/// адресу открывалось бы разное в зависимости от того, была ли сессия.
///
/// Адрес нужен, чтобы его можно было продиктовать механику по телефону:
/// «зайди на els23.ru/app» короче, чем «войди, открой кабинет, промотай
/// вниз».
bool get openedAtDownloadPage => kIsWeb && Uri.base.path == '/app';

class AppDownloadScreen extends StatefulWidget {
  const AppDownloadScreen({Key? key, this.onBack}) : super(key: key);

  /// Возврат назад. `null` — стрелку не рисуем: так экран открывается по
  /// прямому адресу `/app`, откуда возвращаться некуда.
  final VoidCallback? onBack;

  @override
  State<AppDownloadScreen> createState() => _AppDownloadScreenState();
}

class _AppDownloadScreenState extends State<AppDownloadScreen> {
  late Future<AppReleaseResult> _release = AppReleaseApi.fetch();
  bool _busy = false;

  void _reload() {
    setState(() => _release = AppReleaseApi.fetch());
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);

    // Ссылка живёт минуту, поэтому открываем сразу после получения, а не
    // складываем в состояние.
    final String? url = await AppReleaseApi.downloadUrl();
    if (!mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить ссылку. Попробуйте ещё раз')),
      );
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppReleaseResult>(
      future: _release,
      builder: (BuildContext context, AsyncSnapshot<AppReleaseResult> snapshot) {
        final Widget body;
        if (snapshot.connectionState != ConnectionState.done) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          body = _body(snapshot.data ?? const AppReleaseResult());
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 32.0),
          children: <Widget>[_Title(onBack: widget.onBack), body],
        );
      },
    );
  }

  Widget _body(AppReleaseResult result) {
    if (result.notPublished) {
      return const _Message(
        icon: Icons.hourglass_empty,
        title: 'Приложение ещё не выложено',
        text: 'Как только сборка появится на сервере, она будет здесь.',
      );
    }
    if (result.release == null) {
      return _Message(
        icon: Icons.wifi_off,
        title: result.error ?? 'Не получилось',
        text: 'Проверьте связь и попробуйте ещё раз.',
        onRetry: _reload,
      );
    }
    return _Release(
      release: result.release!,
      busy: _busy,
      onDownload: _download,
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({Key? key, this.onBack}) : super(key: key);

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MechanicLayout.screenPadding,
        24.0,
        MechanicLayout.screenPadding,
        16.0,
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(20.0),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back, size: 24.0),
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          const Text('Приложение', style: MechanicLayout.screenTitle),
        ],
      ),
    );
  }
}

/// Выложенная сборка: шапка, кнопка и то, что нужно знать до установки.
class _Release extends StatelessWidget {
  const _Release({
    Key? key,
    required this.release,
    required this.busy,
    required this.onDownload,
  }) : super(key: key);

  final AppRelease release;
  final bool busy;
  final VoidCallback onDownload;

  /// Стоит ли звать обновляться. В браузере — никогда: обновлять там нечего.
  bool get _isUpdate =>
      AppReleaseApi.isInstalledApp &&
      release.versionCode > AppReleaseApi.installedVersionCode;

  /// Установленная версия — свежая. Кнопку показываем всё равно: переставить
  /// приложение бывает нужно и без обновления.
  bool get _isCurrent =>
      AppReleaseApi.isInstalledApp &&
      release.versionCode <= AppReleaseApi.installedVersionCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MechanicLayout.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Head(release: release, isUpdate: _isUpdate, isCurrent: _isCurrent),
          const SizedBox(height: 16.0),
          if (_isUpdate && release.notes != null) ...<Widget>[
            _Card(
              label: 'Что нового',
              text: release.notes!,
            ),
            const SizedBox(height: 14.0),
          ],
          if (!AppReleaseApi.isInstalledApp) ...<Widget>[
            const _Note(
              'Работает без интернета. Фото и отчёты уходят сами, когда '
              'появится связь.',
            ),
            const SizedBox(height: 14.0),
          ],
          SizedBox(
            height: 50.0,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.myColorGreen,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
                ),
              ),
              onPressed: busy ? null : onDownload,
              icon: busy
                  ? const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: ColorApp.myColorWhite,
                      ),
                    )
                  : const Icon(Icons.download, color: ColorApp.myColorWhite),
              label: Text(
                busy
                    ? 'Готовим ссылку'
                    : _isUpdate
                        ? 'Обновить'
                        : 'Скачать',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: ColorApp.myColorWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          if (_isUpdate)
            const Text(
              'Заявки и незаконченные отчёты останутся на месте.',
              style: MechanicLayout.rowLabel,
            )
          else
            const _HowTo(),
          if (release.sha256 != null) ...<Widget>[
            const SizedBox(height: 16.0),
            Text(
              'sha256 ${release.sha256}',
              style: const TextStyle(fontSize: 11.0, color: Color(0xff9E9E9E)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    Key? key,
    required this.release,
    required this.isUpdate,
    required this.isCurrent,
  }) : super(key: key);

  final AppRelease release;
  final bool isUpdate;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final String title = isUpdate ? 'Вышло обновление' : 'ЕЛС для механика';
    final String subtitle;
    if (isUpdate) {
      subtitle = 'У вас ${AppReleaseApi.installedVersionName}, '
          'на сервере ${release.versionName}';
    } else if (isCurrent) {
      subtitle = 'Версия ${release.versionName} — у вас последняя';
    } else {
      subtitle = 'Версия ${release.versionName} · ${release.sizeLabel}';
    }

    return Row(
      children: <Widget>[
        Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            color: ColorApp.myColorGreen.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(
            isUpdate ? Icons.refresh : Icons.smartphone,
            size: 26.0,
            color: ColorApp.myColorGreenAuth,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: MechanicLayout.cardTitle),
              const SizedBox(height: 2.0),
              Text(subtitle, style: MechanicLayout.cardSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Три шага установки. Нужны ровно один раз в жизни телефона, но без них
/// человек упрётся в запрет Android и решит, что приложение сломано.
class _HowTo extends StatelessWidget {
  const _HowTo({Key? key}) : super(key: key);

  static const List<String> _steps = <String>[
    'Нажмите «Скачать» и дождитесь конца загрузки.',
    'Откройте файл. Телефон спросит разрешение — включите установку из '
        'этого источника.',
    'Войдите тем же логином, что и здесь.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Как поставить', style: MechanicLayout.groupLabel),
        const SizedBox(height: 8.0),
        for (int i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text('${i + 1}. ${_steps[i]}',
                style: MechanicLayout.rowLabel),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({Key? key, required this.label, required this.text})
      : super(key: key);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: MechanicLayout.divider),
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: MechanicLayout.groupLabel),
          const SizedBox(height: 6.0),
          Text(text, style: MechanicLayout.rowLabel),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Text(text, style: MechanicLayout.rowLabel),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    Key? key,
    required this.icon,
    required this.title,
    required this.text,
    this.onRetry,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MechanicLayout.screenPadding,
        vertical: 32.0,
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 48.0, color: const Color(0xffBDBDBD)),
          const SizedBox(height: 16.0),
          Text(title, style: MechanicLayout.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8.0),
          Text(text, style: MechanicLayout.rowLabel, textAlign: TextAlign.center),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 16.0),
            TextButton(onPressed: onRetry, child: const Text('Ещё раз')),
          ],
        ],
      ),
    );
  }
}
