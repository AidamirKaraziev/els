import 'package:els/dispatcher/home_dispatcher.dart';
import 'package:els/owner/home_owner.dart';
import 'package:els/screns/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../bloc/user_bloc/user_bloc.dart';
import '../foreman/home_foreman.dart';

/// Экран заставки

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    // TODO: implement initState
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    Future.delayed(const Duration(seconds: 2), (){
      if(idUserTest == 1){
        /// Админ
        return Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HomePage()));
      }else if(idUserTest == 2){
        /// Пропаб
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeForeman()));
      }else if(idUserTest == 5){
        /// Диспетчер
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeDispatcher()));
      }else if(idUserTest == 6){
        /// Пользователь
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeOwner()));
      }
    });
    super.initState();
  }
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children:  [
          const Spacer(),
          Center(child: Lottie.asset('assets/Animation - 1720525933825.json')),
          const Spacer(),
        ],
      ),
    );
  }
}
