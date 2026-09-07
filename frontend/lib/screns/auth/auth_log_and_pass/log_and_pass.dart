// ignore_for_file: use_build_context_synchronously

import 'package:els/app_download/app_download_screen.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/session.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'auth_widget.dart';

///Окно Логин и Пароль

var singleCheckBox = false;

bool openPassword = true;

class LogAndPass extends StatefulWidget {
  const LogAndPass({Key? key}) : super(key: key);

  @override
  State<LogAndPass> createState() => _LogAndPassState();
}

class _LogAndPassState extends State<LogAndPass> {
  final formKey = GlobalKey<FormState>();

  TextEditingController log = TextEditingController();
  TextEditingController pass = TextEditingController();

  /// Идёт ли сейчас вход. Нужен, чтобы двойное нажатие не заводило две
  /// сессии: каждая выдаёт свою пару токенов, и вторая гасит первую.
  bool busy = false;

  /// Что показать человеку под формой. Тексты приходят от бэкенда: там они
  /// согласованы и различают «неверный пароль» и «вход заблокирован».
  String? errorText;

  @override
  void dispose() {
    log.dispose();
    pass.dispose();
    super.dispose();
  }

  /// Вход: пара токенов, профиль, экран по роли.
  ///
  /// Прежняя версия слала на удалённую ручку `/cp/sign-in/` зашитые в код
  /// `email: '1'` и `password: '1'` — введённые логин и пароль в запрос
  /// не попадали вовсе.
  Future<void> auth() async {
    if (busy) return;

    final String email = log.text.trim();
    final String password = pass.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Введите почту и пароль');
      return;
    }

    setState(() {
      busy = true;
      errorText = null;
    });

    http.Response response;
    try {
      response = await Api.login(email: email, password: password);
    } catch (_) {
      setState(() {
        busy = false;
        errorText = 'Сервер недоступен. Проверьте соединение.';
      });
      return;
    }

    if (response.statusCode != 200) {
      // Пять неудачных попыток блокируют вход на 15 минут, пароль короче
      // восьми знаков не принимается — про это бэкенд пишет текстом, и
      // показать надо именно его: иначе человек будет долбить форму
      // правильным паролем и не поймёт, почему тот не подходит.
      setState(() {
        busy = false;
        errorText = ApiError.messageOf(
          response,
          fallback: 'Не удалось войти. Попробуйте ещё раз.',
        );
      });
      return;
    }

    // Токены уже сохранены клиентом. Дальше нужен профиль: без него неизвестна
    // роль, а значит и экран.
    final bool profileLoaded = await loadProfile();
    if (!profileLoaded) {
      await Api.logout();
      setState(() {
        busy = false;
        errorText = 'Вход выполнен, но профиль не загрузился. Повторите попытку.';
      });
      return;
    }

    markSignedIn();
    if (!mounted) return;
    primeData(context);

    setState(() => busy = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => homeScreenForRole(idUserTest)),
      (Route<dynamic> route) => false,
    );

    // Пришли по короткому адресу `els23.ru/app` — за APK, а не в кабинет.
    // Кабинет всё равно кладём под низ: со страницы скачивания механик
    // выходит стрелкой назад и оказывается там, где и ожидает.
    if (openedAtDownloadPage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: AppDownloadScreen(
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(size.width > 550 ? 70.0 : 20.0),
      child: SizedBox(
        width: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Единая лифтовая служба',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorApp.myColorGreenAuth,
                )),
            SizedBox(height: size.height > 650 ? 90.0 : 20.0),
            const Text('Авторизация',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
            SizedBox(height: size.height > 650 ? 40.0 : 10.0),
            const Text('Введите свой логин или адрес электронной почты,'),
            const SizedBox(height: 10.0),
            const Text('а также пароль, для того, чтобы войти в систему'),
            SizedBox(height: size.height > 650 ? 30.0 : 20.0),
            Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: formKey,
              child: TextFormField(
                cursorColor: ColorApp.myColorGray,
                controller: log,
                decoration: const InputDecoration(
                    suffixIcon: Icon(
                      Icons.email_outlined,
                      color: ColorApp.myColorGreenAuth,
                      size: 25.0,
                    ),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                    ),
                    labelText: 'Почта',
                    labelStyle: TextStyle(color: ColorApp.myColorGray)),
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (_) => auth(),
              ),
            ),
            SizedBox(height: size.height > 650 ? 16.0 : 10.0),
            TextFormField(
              cursorColor: ColorApp.myColorGray,
              controller: pass,
              obscureText: openPassword,
              onFieldSubmitted: (_) => auth(),
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        openPassword = !openPassword;
                      });
                    },
                    icon: Icon(
                      openPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 25,
                      color: ColorApp.myColorGreenAuth,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                  ),
                  labelText: 'Пароль',
                  labelStyle: const TextStyle(color: ColorApp.myColorGray)),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: ColorApp.myColorRed),
                ),
              ),
            SizedBox(height: size.height > 650 ? 20.0 : 10.0),
            Row(
              children: [
                Checkbox(
                  activeColor: ColorApp.myColorGreenAuth,
                  value: singleCheckBox,
                  onChanged: (newValue) {
                    setState(() {
                      singleCheckBox = !singleCheckBox;
                      setState(() {});
                    });
                  },
                ),
                const Text('Остоваться в системе'),
              ],
            ),
            SizedBox(height: size.height > 650 ? 30.0 : 20.0),
            busy
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(
                        color: ColorApp.myColorGreenAuth,
                      ),
                    ),
                  )
                : MainButtonApp(
                    textButton: 'ВОЙТИ',
                    press: auth,
                  ),
            const SizedBox(height: 10.0),
            size.width > 380.0
                ? Row(
                    children: [
                      const Text('Забыли пароль?'),
                      DropdownWindow(size: size),
                    ],
                  )
                : Column(
                    children: [
                      const Text('Забыли пароль?'),
                      DropdownWindow(size: size),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
