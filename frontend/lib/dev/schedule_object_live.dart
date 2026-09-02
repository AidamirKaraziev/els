import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../helper/api_client.dart';
import '../helper/class_colors.dart';
import '../helper/session.dart';
import '../screns/schedule/models/schedule_role.dart';
import '../screns/schedule/object/repository/api_schedule_object_repository.dart';
import '../screns/schedule/object/view/schedule_object_screen.dart';
import '../screns/schedule/object/wizard/repository/api_schedule_wizard_repository.dart';

/// Отдельная точка входа: экран графика объекта на **живом** бэкенде.
///
/// Соседняя `schedule_object_preview.dart` показывает тот же экран на
/// фикстуре — но ровно поэтому на ней не проверить переходы: карточка работы
/// и карточка сотрудника грузятся из сети, а карточка сотрудника вдобавок
/// смотрит на роль вошедшего (`idUserTest` в `helper/session.dart`) и на
/// право `USER_READ`. Ни того, ни другого у фикстуры нет.
///
/// **Профиль грузим сразу после входа.** Без `loadProfile()` роль остаётся
/// нулём, `canOpenEmployeeCard` отвечает `false`, и плашка ответственного
/// молчит — не потому, что прав не хватило, а потому что спрашивать было
/// некого. Такую тишину легко принять за отказ сервера.
///
/// Запуск (бэкенд поднят через `make up`, nginx отдаёт API на 8080):
///
///     flutter run -t lib/dev/schedule_object_live.dart -d chrome \
///       --dart-define=API_ORIGIN=http://localhost:8080
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleObjectLiveApp());
}

class ScheduleObjectLiveApp extends StatelessWidget {
  const ScheduleObjectLiveApp({Key? key}) : super(key: key);

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
      home: const _LiveForm(),
    );
  }
}

/// Вход, объект и год — всё, чего экрану не хватает без оболочки.
class _LiveForm extends StatefulWidget {
  const _LiveForm({Key? key}) : super(key: key);

  @override
  State<_LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends State<_LiveForm> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _objectId = TextEditingController(text: '25');
  late final TextEditingController _year =
      TextEditingController(text: '${DateTime.now().year + 1}');

  bool _busy = false;
  String? _error;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    // Пара токенов могла остаться с прошлого запуска. Профиль всё равно
    // перечитываем: роль после перезагрузки страницы пустая.
    Api.restoreSession().then((bool ok) async {
      final bool profile = ok && await loadProfile();
      if (mounted) setState(() => _signedIn = profile);
    });
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _objectId.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final http.Response response = await Api.login(
        email: _login.text.trim(),
        password: _password.text,
      );
      if (response.statusCode != 200) {
        setState(() => _error = 'Войти не удалось: проверьте почту и пароль');
        return;
      }
      final bool profile = await loadProfile();
      setState(() {
        _signedIn = profile;
        _error = profile ? null : 'Вошли, но профиль не загрузился';
      });
    } catch (error) {
      setState(() => _error = 'Войти не удалось: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Чьими глазами открыть экран. Берём из роли вошедшего: подставлять её
  /// руками значило бы проверять не то, что увидит человек.
  ScheduleRole get _role =>
      idUserTest == Roles.foreman ? ScheduleRole.foreman : ScheduleRole.admin;

  void _openScreen() {
    final int? objectId = int.tryParse(_objectId.text.trim());
    final int? year = int.tryParse(_year.text.trim());
    if (objectId == null || year == null) {
      setState(() => _error = 'Объект и год — числа');
      return;
    }
    setState(() => _error = null);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ScheduleObjectScreen(
          objectId: objectId,
          repository: ApiScheduleObjectRepository(),
          wizardRepository: (String modelName) =>
              ApiScheduleWizardRepository(modelName: modelName),
          role: _role,
          initialYear: year,
          objectName: 'Объект $objectId',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text('График объекта — живой бэкенд'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!_signedIn) ...<Widget>[
                  _field(_login, 'Почта'),
                  _field(_password, 'Пароль', obscure: true),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _busy ? null : _signIn,
                    style: _buttonStyle(),
                    child: Text(_busy ? 'Входим…' : 'Войти'),
                  ),
                ] else ...<Widget>[
                  // Роль подписью: по ней сразу видно, тем ли человеком
                  // открыт экран, — а от неё зависит и путь в сотрудника.
                  Text(
                    'Вошли как: ${Roles.names[idUserTest] ?? 'роль $idUserTest'}',
                    style: const TextStyle(fontSize: 14.0),
                  ),
                  const SizedBox(height: 12.0),
                  _field(_objectId, 'ID объекта'),
                  _field(_year, 'Год графика'),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _openScreen,
                    style: _buttonStyle(),
                    child: const Text('Открыть график'),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12.0),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: ColorApp.myColorRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      );
}
