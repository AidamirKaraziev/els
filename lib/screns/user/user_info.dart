import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/class_colors.dart';

/// Блок User Info

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.all(20.0),
              height: 250,
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ///Участок
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 20.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Участок'),
                          const SizedBox(height: 10.0),
                          if (state is UserGetState)
                            Text(
                                state.getUser[0]['company_id'] != null
                                    ? 'Участок № ${state.getUser[0]['company_id']}'
                                    : 'Не заполнено',
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),

                  ///Должность
                  Row(
                    children: [
                      const Icon(Icons.person_outline_outlined),
                      const SizedBox(width: 20.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Должность'),
                          const SizedBox(height: 10.0),
                          if (state is UserGetState)
                            Text(
                                state.getUser[0]['role_id']['name'] ??
                                    'Не заполнено',
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),

                  ///Компания
                  Row(
                    children: [
                      const Icon(Icons.domain),
                      const SizedBox(width: 20.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Компания'),
                          const SizedBox(height: 10.0),
                          if (state is UserGetState)
                            Text(
                                state.getUser[0]['company_id'] ??
                                    'Не заполнено',
                                style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
