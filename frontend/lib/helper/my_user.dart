import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../bloc/user_bloc/user_bloc.dart';
import '../screns/auth/auth_log_and_pass/log_and_pass.dart';
import '../screns/home_page/home_page.dart';
import '../screns/user/user_contact.dart';
import '../screns/user/user_profile.dart';
import 'class_colors.dart';
import 'package:els/helper/api_config.dart';

/// Иконка с фото ============================
class MyUser extends StatefulWidget {
  const MyUser({Key? key}) : super(key: key);

  @override
  State<MyUser> createState() => _MyUserState();
}
class _MyUserState extends State<MyUser> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Column(
          children: [
            if(state is UserGetState)
            CircularPercentIndicator(
              radius: size.width > 350 ? 33.0 : 23.0,
              lineWidth: 5.0,
              percent: 0.7,
              progressColor: ColorApp.myColorGreenAuth,
              backgroundColor: ColorApp.myColorAvatar,
              center: GestureDetector(
                onTap: () async {
                  IntTest.indexScreens = 8;
                  myStream.add(IntTest.indexScreens);
                  setState(() {});
                },
                child: StreamBuilder(
                  stream: myStream.stream,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    return CircleAvatar(
                      radius: size.width > 350 ? 29.0 : 20.0,
                      backgroundColor: Colors.transparent,
                      backgroundImage: const AssetImage('assets/user.png'),
                      foregroundImage: newPhoto != '' ?  NetworkImage('${ApiConfig.scheme}://$newPhoto') : NetworkImage('${ApiConfig.scheme}://${userProfile[0]['photo']}'),
                    );
                  },
                )

              ),
            ),
          ],
        );
      },
    );
  }
}
/// ==========================================