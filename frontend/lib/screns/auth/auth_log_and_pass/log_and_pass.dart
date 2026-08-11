// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/splash_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../bloc/user_bloc/user_bloc.dart';
import '../../../helper/button/my_button.dart';
import 'package:http/http.dart' as http;
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;


    bool progressTest = true;
    funTest(){
      print('worksssss');
    }

    // Future<void> sendOptionsRequest() async {
    //   var client = HttpClient();
    //   var url = Uri.parse('${ApiConfig.base}/cp/sign-in/');
    //
    //   var request = await client.openUrl('OPTIONS', url);
    //   request.headers.set('Content-Type', 'application/json');
    //   request.headers.set('Authorization', 'Bearer ${IntTest.token}');
    //
    //   var response = await request.close();
    //   var responseBody = await response.transform(utf8.decoder).join();
    //
    //   print(response.statusCode);
    //   print(responseBody);
    //   print('отработала');
    // }

    /// Проверка Логин и Пароль получение токен ===========
    auth() async {

      SharedPreferences preferences = await SharedPreferences.getInstance();
      var response = await http.post(Uri.parse('${ApiConfig.base}/cp/sign-in/'),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
          },
          body: json.encode({
            'email': '1',//log.text,
            'password': '1',//pass.text,
          }));
      var ress = jsonDecode(response.body);
      /// pr@mail.ru 1111 прораб
      /// d@mail.ru 1111 Дипетчер
      /// tex@plk-krd.ru 0000 Виталик прораб
      /// owner@mail.ru 1111 собственик
      // print(ress);
      IntTest.token = ress['data']['token'];
      await preferences.setString('token', ress['data']['token']);
      // print(IntTest.token);
      if (IntTest.token != null) {
        UserBloc().add(UserGetEvent());
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SplashScreen()));
        // if(idUserTest == 1) {
        //   Navigator.of(context).push(
        //     MaterialPageRoute(builder: (context) => const HomePage()));
        // }
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
                // if(userProfile[0]['role_id']['id'] == 5){
                //   getListApplication();
                //   Navigator.of(context).push(
                //       MaterialPageRoute(builder: (context) => const HomePageDispatcher()));
                // }
                // else if (userProfile[0]['role_id']['id'] == 1){
                //   Navigator.of(context).push(
                //       MaterialPageRoute(builder: (context) => const HomePage()));
                // }
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


