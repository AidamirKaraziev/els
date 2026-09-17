/// Проверка крэш-репортов: две кнопки, которые роняют приложение.
///
/// В самом приложении такой кнопки нет и не будет — это dev-точка. Нужна,
/// чтобы увидеть событие в Sentry с правильным `release` до того, как APK
/// уедет механикам, и чтобы после обновления `sentry_flutter` убедиться,
/// что перехват не отвалился.
///
/// Запуск (DSN — из проекта Sentry, в репозиторий не попадает):
///
///     flutter run -t lib/dev/crash_preview.dart -d chrome \
///       --dart-define=SENTRY_DSN=https://… \
///       --dart-define=APP_VERSION_NAME=0.0.0-dev \
///       --dart-define=APP_VERSION_CODE=1
///
/// Без DSN страница работает, но события никуда не уходят — об этом
/// написано на самой странице.
///
/// В консоли при старте будет «Zone mismatch» — это только веб: там
/// `sentry_flutter` заводит биндинг в корневой зоне, а приложение
/// запускает в своей `runZonedGuarded`. Событий это не теряет (проверено
/// 2026-09-17: все три кнопки долетели), а в APK зоны нет вовсе — там
/// перехват через `PlatformDispatcher.onError`.
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';

import '../helper/class_colors.dart';
import '../helper/crash_reporting.dart';

void main() {
  // Биндинг инициализирует сам Sentry — до `runApp` здесь ничего не нужно.
  CrashReporting.run(() => runApp(const CrashPreviewApp()));
}

class CrashPreviewApp extends StatelessWidget {
  const CrashPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: ColorApp.myColorWhite),
      home: const _PreviewPage(),
    );
  }
}

class _PreviewPage extends StatefulWidget {
  const _PreviewPage({Key? key}) : super(key: key);

  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  bool _breakBuild = false;

  @override
  Widget build(BuildContext context) {
    if (_breakBuild) {
      // Ошибка в build — самый частый вид падения у экранов подрядчика:
      // null там, где ждали значение. Ловится через FlutterError.onError.
      throw StateError('crash_preview: ошибка при сборке виджета');
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: const Text('Крэш-репорты — проверка'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ColorApp.kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              CrashReporting.enabled
                  ? 'Sentry включён · release ${CrashReporting.release}'
                  : 'DSN не задан — события никуда не уйдут',
              style: TextStyle(
                color: CrashReporting.enabled
                    ? ColorApp.myColorBlack
                    : ColorApp.myColorRed,
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                // Исключение в обработчике нажатия: не ловится ни одним
                // виджетом, уходит в зону — её и держит Sentry.
                throw StateError('crash_preview: исключение в обработчике');
              },
              child: const Text('Исключение в обработчике'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () => setState(() => _breakBuild = true),
              child: const Text('Ошибка сборки виджета'),
            ),
            const SizedBox(height: 12.0),
            OutlinedButton(
              onPressed: () async {
                // Отправка руками — для проверки, что DSN вообще рабочий,
                // без падения.
                await CrashReporting.report(
                  StateError('crash_preview: тестовое событие'),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Событие отправлено')),
                );
              },
              child: const Text('Отправить тестовое событие'),
            ),
          ],
        ),
      ),
    );
  }
}
