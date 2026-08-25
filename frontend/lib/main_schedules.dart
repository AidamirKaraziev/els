import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screns/schedule/bloc/schedules_bloc.dart';
import 'screns/schedule/view/schedules_screen.dart';

/// Отладочный вход в раздел «Графики» на время фазы отрисовки.
///
/// Боевой `main.dart` не трогаем: там сессия, токены и подмена старых экранов —
/// это конец фазы. Здесь нужен один экран поверх фикстуры, чтобы вёрстку можно
/// было смотреть глазами и спорить о ней до того, как появятся новые ручки.
///
/// ```bash
/// flutter run -d chrome -t lib/main_schedules.dart
/// ```
///
/// Ни `Api`, ни `Session`, ни `HintSettings` тут не поднимаются: репозиторий по
/// умолчанию — `FixtureSchedulesRepository`, сеть не нужна вовсе.
void main() {
  runApp(const SchedulesPreviewApp());
}

class SchedulesPreviewApp extends StatelessWidget {
  const SchedulesPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Настройки повторяют боевой `main.dart`: без локали `ru` названия
      // месяцев в тултипе клетки выпадут по-английски, а шрифт разъедется —
      // и смотреть вёрстку будет не на что.
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.ubuntuTextTheme(),
      ),
      home: BlocProvider<SchedulesBloc>(
        create: (_) => SchedulesBloc(),
        child: const SchedulesScreen(),
      ),
    );
  }
}
