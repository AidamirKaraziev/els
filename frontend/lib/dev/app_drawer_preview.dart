/// Набросок единого бургера — вид без сервера и без входа.
///
/// Два бургера рядом: слева админ, справа прораб. Тап по пункту переносит
/// подсветку; «Выйти» открывает диалог подтверждения. На «Работы» подставные
/// таблетки: 3 в работе, 1 с проблемой.
///
/// Запуск:
///
///     flutter run -t lib/dev/app_drawer_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../helper/count_chip.dart';
import '../helper/session.dart';
import '../navigation/app_drawer.dart';
import '../navigation/app_section.dart';
import '../navigation/logout_confirm.dart';

void main() {
  runApp(const AppDrawerPreviewApp());
}

class AppDrawerPreviewApp extends StatelessWidget {
  const AppDrawerPreviewApp({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text(
          'Единый бургер — набросок',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(ColorApp.kPadding),
        child: Wrap(
          spacing: 40.0,
          runSpacing: 28.0,
          children: <Widget>[
            _DrawerSample(
              caption: 'Админ — открыта «Главная»',
              roleId: Roles.admin,
              userName: 'Иван Петров',
              initial: AppSection.home,
            ),
            _DrawerSample(
              caption: 'Прораб — открыты «Работы»',
              roleId: Roles.foreman,
              userName: 'Сергей Козлов',
              initial: AppSection.works,
            ),
          ],
        ),
      ),
    );
  }
}

/// Бургер в рамке, с подписью, живой: подсветка ходит за тапом.
class _DrawerSample extends StatefulWidget {
  const _DrawerSample({
    Key? key,
    required this.caption,
    required this.roleId,
    required this.userName,
    required this.initial,
  }) : super(key: key);

  final String caption;
  final int roleId;
  final String userName;
  final AppSection initial;

  @override
  State<_DrawerSample> createState() => _DrawerSampleState();
}

class _DrawerSampleState extends State<_DrawerSample> {
  late AppSection _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            widget.caption,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w300,
              color: ColorApp.myColorGray,
            ),
          ),
        ),
        Container(
          width: 304.0,
          height: 640.0,
          decoration: BoxDecoration(
            border: Border.all(color: ColorApp.myColorGrayBorder),
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: AppDrawer(
            current: _current,
            roleId: widget.roleId,
            userName: widget.userName,
            onSelect: (AppSection s) => setState(() => _current = s),
            onLogout: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final bool yes = await confirmLogout(context);
              messenger.showSnackBar(
                SnackBar(content: Text(yes ? 'Вышли' : 'Остались')),
              );
            },
            trailing: const <AppSection, Widget>{
              AppSection.works: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CountChip(count: 3, tone: CountTone.running),
                  SizedBox(width: 4.0),
                  CountChip(count: 1, tone: CountTone.problem),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }
}
