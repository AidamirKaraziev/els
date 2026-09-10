/// Набросок раздела «Отчёты» с блоком дефектных актов — вид без сервера и
/// без входа.
///
/// Кадра в макете нет, поэтому набросок показывается отдельно на утверждение,
/// по правилу «макет утверждается до логики». Данные — из
/// `FixtureWorksReportRepository`: три объекта с нулём, тремя и семнадцатью
/// актами за год; сузив период до месяца без актов (например, июнь), можно
/// увидеть плитку сводки в сером виде.
///
/// Запуск:
///
///     flutter run -t lib/dev/report_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/user_bloc/user_bloc.dart';
import '../screns/report/report_screen.dart';
import '../screns/report/repository/fixture_works_report_repository.dart';

void main() {
  runApp(const ReportPreviewApp());
}

class ReportPreviewApp extends StatelessWidget {
  const ReportPreviewApp({Key? key}) : super(key: key);

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
      theme: ThemeData(textTheme: GoogleFonts.ubuntuTextTheme()),
      // `UserBloc` нужен шапке: аватар вошедшего читает его состояние.
      // Пустой блок ничего не запрашивает — аватара просто не будет.
      // Меню пустое: боковое меню подрядчика тянет за собой вход в систему.
      home: BlocProvider<UserBloc>(
        create: (_) => UserBloc(),
        child: const ReportScreen(
          drawer: Drawer(),
          repository: FixtureWorksReportRepository(),
        ),
      ),
    );
  }
}
