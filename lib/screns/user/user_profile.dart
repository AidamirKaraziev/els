import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/class_colors.dart';

/// Блок User Profile

class UserProfile extends StatelessWidget {
  const UserProfile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Профиль', style: TextStyle(fontWeight: FontWeight.w600),),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: ColorApp.myColorWhite,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(state is UserGetState)
                    Badge(
                      smallSize: 30.0,
                      largeSize: 50.0,
                      alignment: const AlignmentDirectional(100,90),
                      backgroundColor: ColorApp.myColorGreen,
                      label: IconButton(onPressed: (){},icon: const Icon(Icons.camera_alt_outlined,color: ColorApp.myColorWhite,)),
                      child: CircleAvatar(
                        radius: 70.0,
                        backgroundImage: const AssetImage('assets/user.png'),
                        foregroundImage: NetworkImage('http://${state.getUser[0]['photo']}'),
                    )),
                  const SizedBox(height: 10.0),
                  if(state is UserGetState)
                  Center(
                    child: Text(state.getUser[0]['name'] != null ? '${state.getUser[0]['name']}' : 'Не заполнено',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10.0),
                  ///Кнопка Редактировать
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        side: BorderSide(
                            color: Colors.grey.shade400, width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: () {},
                      child: Text('Редактировать',
                          style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.grey.shade400))),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}