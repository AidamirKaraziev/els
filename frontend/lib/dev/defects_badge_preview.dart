/// Набросок значка-счётчика дефектных актов — вид без сервера и без входа.
///
/// Показывает значок ровно в тех двух местах, где он будет жить: в строке
/// заголовка «Техническое обслуживание» окна «График объекта» (рядом с
/// переключателем года) и в строке «Дефекты объекта» блока «Документы» окна
/// объекта прораба. Числа подставные.
///
/// Нулевое состояние — серый значок, «дефектных актов не было» подсказкой
/// при наведении: 6 сентября 2026 на этом же наброске выбирали между
/// подсказкой и подписью текстом, выбрали подсказку.
///
/// Запуск:
///
///     flutter run -t lib/dev/defects_badge_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../foreman/defects/defects_badge.dart';
import '../helper/class_colors.dart';
import '../screns/schedule/object/widgets/object_block.dart';
import '../screns/schedule/widgets/schedule_year_picker.dart';

void main() {
  runApp(const DefectsBadgePreviewApp());
}

class DefectsBadgePreviewApp extends StatelessWidget {
  const DefectsBadgePreviewApp({Key? key}) : super(key: key);

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

  static const int _year = 2026;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text(
          'Значок дефектных актов — набросок',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ColorApp.kPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760.0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Caption('Окно «График объекта» — есть дефекты'),
                _ScheduleHeading(count: 3),
                SizedBox(height: 28.0),
                _Caption('Окно «График объекта» — дефектов нет'),
                _ScheduleHeading(count: 0),
                SizedBox(height: 28.0),
                _Caption('Трёхзначное число — за год на большом объекте'),
                _ScheduleHeading(count: 128),
                SizedBox(height: 40.0),
                _Caption('Окно «Объект» — есть дефекты'),
                _DefectsRow(count: 3),
                SizedBox(height: 28.0),
                _Caption('Окно «Объект» — дефектов нет'),
                _DefectsRow(count: 0),
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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w300,
          color: ColorApp.myColorGray,
        ),
      ),
    );
  }
}

/// Строка заголовка блока «Техническое обслуживание» с лентой-заглушкой.
class _ScheduleHeading extends StatelessWidget {
  const _ScheduleHeading({Key? key, required this.count}) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return ObjectBlock(
      title: 'Техническое обслуживание',
      titleTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DefectsBadge(
            count: count,
            year: _PreviewPage._year,
            onTap: () {},
          ),
          const SizedBox(width: 8.0),
          ScheduleYearPicker(
            year: _PreviewPage._year,
            onChanged: (int _) {},
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 56.0,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16.0),
        decoration: objectCardDecoration(),
        child: const Text(
          'Плановые ТО',
          style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ),
    );
  }
}

/// Строка «Дефекты объекта» из блока «Документы» окна объекта прораба.
class _DefectsRow extends StatelessWidget {
  const _DefectsRow({Key? key, required this.count}) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Журнал',
                  style:
                      TextStyle(fontWeight: FontWeight.w300, fontSize: 12.0)),
              SizedBox(height: 5.0),
              Text('Дефекты',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0)),
            ],
          ),
        ),
        Expanded(
          flex: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            height: 50.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(width: 1, color: ColorApp.myColorAvatar),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.report_gmailerrorred_outlined,
                    color: ColorApp.myColorGreen),
                const SizedBox(width: 10.0),
                const Text(
                  'Дефекты объекта',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
                ),
                const Spacer(),
                DefectsBadge(
                  count: count,
                  year: _PreviewPage._year,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
