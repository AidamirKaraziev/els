import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bloc/user_bloc/user_bloc.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../home_page/home_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    /// Проверка Логин и Пароль получение токен ===========
    auth() async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      var response = await http.post(Uri.parse('http://${IntTest.myIp}/api/v1/cp/sign-in/'),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
          },
          body: json.encode({
            'email': log.text,
            'password': pass.text,
          }));
      var ress = jsonDecode(response.body);
      IntTest.token = ress['data']['token'];
      await preferences.setString('token', ress['data']['token']);
      // print(IntTest.token);
      if (IntTest.token != null) {
        UserBloc().add(UserGetEvent());
      }
    }
    /// ===================================================
    
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
                validator: (email) =>
                    email != null && !EmailValidator.validate(email)
                        ? 'Не корректный email'
                        : null,
              ),
            ),
            SizedBox(height: size.height > 650 ? 16.0 : 10.0),
            TextFormField(
              cursorColor: ColorApp.myColorGray,
              controller: pass,
              obscureText: openPassword,
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
            MainButtonApp(
              textButton: 'ВОЙТИ',
              press: () async {
                await auth();
                // ignore: use_build_context_synchronously
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const HomePage(
                          // stream: menuController.stream
                          )),
                );
              },
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
