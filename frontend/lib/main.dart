import 'package:els/helper/api_client.dart';
import 'package:els/helper/hints/hint_settings.dart';
import 'package:els/helper/session.dart';
import 'package:els/mechanic/data/push_service.dart';
import 'package:els/navigation/app_route.dart';
import 'package:els/navigation/app_router.dart';
import 'package:els/screns/employee/bloc/employee_bloc.dart';
import 'package:els/screns/object/bloc/object_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// SDK-пакет, в `pubspec.lock` уже есть транзитивно. В `pubspec.yaml` не
// вписан намеренно: правка pubspec заставит `flutter build` самому запустить
// `pub get`, а CI и локальная машина требуют разных `intl`.
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'bloc/company_bloc/company_bloc.dart';
import 'bloc/user_bloc/user_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Токены лежат в SharedPreferences, а его нельзя трогать до инициализации
  // плагинов. Сборка такую ошибку не ловит — она вылезает только в рантайме.
  WidgetsFlutterBinding.ensureInitialized();

  // Адрес раздела без `#`: `els23.ru/objects`, а не `els23.ru/#/objects`.
  // nginx на любой путь отдаёт `index.html`, так что перезагрузка не ломает.
  // Вне web вызов ничего не делает.
  usePathUrlStrategy();

  // Обновить токен не удалось — значит сессии больше нет, и решение здесь
  // ровно одно: экран входа. Клиент API сам до навигатора не дотянется.
  Api.onSessionExpired = goToLogin;

  // Настройки подсказок читаются один раз и дальше живут в памяти.
  // Не ждём результата: подсказки — украшение, и задерживать из-за них
  // первый кадр приложения незачем.
  HintSettings.instance.load();

  // Push: Firebase и канал уведомлений со звуком. До входа, потому что канал
  // должен существовать к моменту, когда система покажет первый push в
  // закрытое приложение. Вне Android — пустой вызов. Первый кадр не ждёт.
  PushService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Событий здесь больше нет. Раньше пять блоков стреляли запросами прямо
      // при запуске — то есть до входа и с пустым токеном. Пока ручки были
      // открыты, данные приходили; теперь на каждый такой запрос придёт `401`.
      // Списки догружаются после входа, в `primeData`.
      providers: [
        BlocProvider<EmployeeBloc>(create: (context) => EmployeeBloc()),
        BlocProvider<CompanyBloc>(create: (context) => CompanyBloc()),
        BlocProvider<UserBloc>(create: (context) => UserBloc()),
        BlocProvider<MyObjectBloc>(create: (context) => MyObjectBloc()),
      ],
      child: MaterialApp.router(
        routerDelegate: appRouter,
        routeInformationParser: const AppRouteInformationParser(),
        backButtonDispatcher: RootBackButtonDispatcher(),
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
      ),
    );
  }
}
