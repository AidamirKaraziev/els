/// Набросок полосы состояния механика и плашки «вышла версия» — без сервера.
///
/// Все состояния столбиком в рамке телефона: офлайн с очередью и без,
/// отправка, отказ сервера, ошибка сервера и плашка обновления над полосой.
/// Числа подставные. Кадра в Figma для этой полосы нет — набросок и есть макет.
///
/// Запуск:
///
///     flutter run -t lib/dev/mechanic_strip_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_download/app_release.dart';
import '../helper/class_colors.dart';
import '../mechanic/data/mechanic_workspace.dart';
import '../mechanic/status_strip.dart';

void main() {
  runApp(const MechanicStripPreviewApp());
}

class MechanicStripPreviewApp extends StatelessWidget {
  const MechanicStripPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('ru', '')],
      theme: ThemeData(
        scaffoldBackgroundColor: ColorApp.myColorTransparent,
        textTheme: GoogleFonts.ubuntuTextTheme(),
      ),
      home: const _PreviewPage(),
    );
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({Key? key}) : super(key: key);

  static const AppRelease _release = AppRelease(
    versionName: '1.0.3',
    versionCode: 4,
    size: 71647942,
    notes: 'Индикатор сети в шапке',
  );

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text(
          'Полоса состояния механика — набросок',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ColorApp.kPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Caption('Офлайн, в очереди 3'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(offline: true, pending: 3),
                  onOpenQueue: noop,
                ),
                const _Caption('Офлайн, очередь пуста'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(offline: true),
                  onOpenQueue: noop,
                ),
                const _Caption('Сеть есть, очередь уходит'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(pending: 2),
                  onOpenQueue: noop,
                ),
                const _Caption('Сервер отклонил одну отметку'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(pending: 1, rejected: 1),
                  onOpenQueue: noop,
                ),
                const _Caption('Сервер отвечает ошибкой'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(
                    lastError: 'Сервер не отдал данные',
                    pending: 2,
                  ),
                  onOpenQueue: noop,
                ),
                const _Caption('Всё хорошо — полосы нет'),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(),
                  onOpenQueue: noop,
                ),
                const _Caption('Вышла версия + офлайн — как в шапке'),
                MechanicUpdateBanner(
                  release: _release,
                  onOpen: noop,
                  onDismiss: noop,
                ),
                MechanicStatusStrip(
                  status: const WorkspaceStatus(offline: true, pending: 3),
                  onOpenQueue: noop,
                ),
                Container(
                  height: 120.0,
                  color: ColorApp.myColorWhite,
                  alignment: Alignment.center,
                  child: const Text(
                    'заявки…',
                    style: TextStyle(color: ColorApp.myColorGrayText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Подпись над образцом — только для наброска, в приложение не идёт.
class _Caption extends StatelessWidget {
  const _Caption(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorGrayText),
      ),
    );
  }
}
