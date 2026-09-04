import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../mechanic/data/objects.dart';
import '../mechanic/screens/objects_screen.dart';

/// Набросок вкладки «Объекты» — вид без сервера и без входа в приложение.
///
/// Кадр `1826:210` в макете есть, но выгружен не был, поэтому вёрстка собрана
/// из приёмов карточки заявок и показывается отдельно на утверждение — по
/// правилу «макет утверждается до логики».
///
/// Объекты здесь подставные: в приложении список собирается из работ
/// механика, лежащих в локальной базе (`mechanic/data/objects.dart`).
///
/// Запуск:
///
///     flutter run -t lib/dev/objects_screen_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ObjectsScreenPreviewApp());
}

class ObjectsScreenPreviewApp extends StatelessWidget {
  const ObjectsScreenPreviewApp({Key? key}) : super(key: key);

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
      home: const MechanicObjectsScreen(objects: _objects),
    );
  }
}

const List<MechanicObject> _objects = <MechanicObject>[
  MechanicObject(
    id: 12,
    name: 'Лифт 12',
    address: 'улица Ленина 45, подъезд 2',
    badge: 'Лифт',
  ),
  MechanicObject(
    id: 8,
    name: 'Пассажирский подъёмник 3',
    address: 'проспект Строителей 7, корпус 1',
    badge: 'Лифт',
  ),
  MechanicObject(
    id: 21,
    name: 'Травалатор 1',
    address: 'Торговый центр «Аврора», нижний уровень',
    badge: 'Травалатор',
  ),
  // Объект без адреса и без типа: так карточка выглядит, когда бэкенд
  // прислал только название.
  MechanicObject(id: 34, name: 'Эскалатор 4'),
];
