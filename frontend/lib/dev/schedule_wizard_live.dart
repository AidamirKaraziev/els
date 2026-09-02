import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/api_client.dart';
import '../helper/class_colors.dart';
import '../screns/schedule/object/wizard/repository/api_maintenance_program_repository.dart';
import '../screns/schedule/object/wizard/repository/api_schedule_wizard_repository.dart';
import '../screns/schedule/object/wizard/view/schedule_wizard_screen.dart';

/// Отдельная точка входа: мастер расстановки на **живом** бэкенде.
///
/// Соседняя `schedule_wizard_preview.dart` показывает все три расклада без
/// сервера — но ровно поэтому на ней не видно того, ради чего мастер сажали
/// на ручку: как отвечает `GET /planned-to/preview/` на настоящий объект,
/// подбирается ли якорь по прошлому году и что приходит в 422. До нового
/// экрана графика из оболочки подрядчика дороги пока нет, а логиниться
/// мастеру всё равно надо — отсюда своя маленькая форма входа.
///
/// Запуск (бэкенд поднят через `make up`, nginx отдаёт API на 8080):
///
///     flutter run -t lib/dev/schedule_wizard_live.dart -d chrome \
///       --dart-define=API_ORIGIN=http://localhost:8080
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleWizardLiveApp());
}

class ScheduleWizardLiveApp extends StatelessWidget {
  const ScheduleWizardLiveApp({Key? key}) : super(key: key);

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

/// Вход и параметры объекта — всё, чего мастеру не хватает без оболочки.
class _LiveForm extends StatefulWidget {
  const _LiveForm({Key? key}) : super(key: key);

  @override
  State<_LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends State<_LiveForm> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _objectId = TextEditingController(text: '1');
  late final TextEditingController _year =
      TextEditingController(text: '${DateTime.now().year + 1}');

  /// Модель оборудования: в ответе предпросмотра её нет, в приложении она
  /// приходит из карточки объекта. Здесь карточки нет — печатаем руками, на
  /// шаге «Программа модели» она только подписью.
  final TextEditingController _model = TextEditingController(text: 'LIFT');

  /// Та же модель числом: по нему уходят запросы программы. В приложении он
  /// приходит из карточки объекта — здесь его печатают руками.
  final TextEditingController _modelId = TextEditingController(text: '1');

  bool _busy = false;
  String? _error;

  /// Вошли ли уже. Токен живёт в `TokenStore`, и на второй объект повторный
  /// вход не нужен.
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    // Пара токенов могла остаться с прошлого запуска — тогда форма входа
    // не нужна вовсе.
    Api.restoreSession().then((bool ok) {
      if (mounted) setState(() => _signedIn = ok);
    });
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _objectId.dispose();
    _year.dispose();
    _model.dispose();
    _modelId.dispose();
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
      final bool ok = response.statusCode == 200;
      setState(() {
        _signedIn = ok;
        _error = ok ? null : 'Войти не удалось: проверьте почту и пароль';
      });
    } catch (error) {
      setState(() => _error = 'Войти не удалось: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openWizard() {
    final int? objectId = int.tryParse(_objectId.text.trim());
    final int? year = int.tryParse(_year.text.trim());
    if (objectId == null || year == null) {
      setState(() => _error = 'Объект и год — числа');
      return;
    }
    setState(() => _error = null);

    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ScheduleWizardScreen(
          repository:
              ApiScheduleWizardRepository(modelName: _model.text.trim()),
          programRepository: ApiMaintenanceProgramRepository(),
          objectId: objectId,
          year: year,
          modelId: int.tryParse(_modelId.text.trim()),
          modelName: _model.text.trim(),
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
        title: const Text('Мастер расстановки — живой бэкенд'),
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
                  _field(_objectId, 'ID объекта'),
                  _field(_year, 'Год графика'),
                  _field(_model, 'Модель оборудования (подпись)'),
                  _field(_modelId, 'ID модели оборудования'),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _openWizard,
                    style: _buttonStyle(),
                    child: const Text('Открыть мастер'),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12.0),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorRed),
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
