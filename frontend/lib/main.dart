import 'package:els/helper/api_client.dart';
import 'package:els/helper/session.dart';
import 'package:els/helper/splash_screen.dart';
import 'package:els/screns/auth/auth.dart';
import 'package:els/screns/employee/bloc/employee_bloc.dart';
import 'package:els/screns/object/bloc/object_bloc.dart';
import 'package:els/screns/task/bloc_task/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/company_bloc/company_bloc.dart';
import 'bloc/user_bloc/user_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Токены лежат в SharedPreferences, а его нельзя трогать до инициализации
  // плагинов. Сборка такую ошибку не ловит — она вылезает только в рантайме.
  WidgetsFlutterBinding.ensureInitialized();

  // Обновить токен не удалось — значит сессии больше нет, и решение здесь
  // ровно одно: экран входа. Клиент API сам до навигатора не дотянется.
  Api.onSessionExpired = goToLogin;

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
        BlocProvider<TaskBloc>(create: (context) => TaskBloc()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
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
        home: const RootGate(),
      ),
    );
  }
}

/// Первый экран: решает, продолжаем прежнюю сессию или просим войти.
///
/// Access живёт 30 минут, поэтому «войти один раз и работать» держится не на
/// нём, а на refresh-токене: он лежит на диске, и при запуске мы меняем его
/// на свежую пару. Без этого перезагрузка вкладки требовала бы пароль.
class RootGate extends StatefulWidget {
  const RootGate({Key? key}) : super(key: key);

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late final Future<bool> _restored = _restore();

  Future<bool> _restore() async {
    if (!await Api.restoreSession()) return false;
    if (!await loadProfile()) return false;

    markSignedIn();
    // Данные тянем после того, как роль известна: клиенту часть списков
    // закрыта правами, и спрашивать их незачем.
    if (mounted) primeData(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restored,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        if (snapshot.data == true) {
          return homeScreenForRole(idUserTest);
        }
        return const Auth();
      },
    );
  }
}
