import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/class_colors.dart';

///Блок User Contact

class UserContact extends StatelessWidget {
  const UserContact({
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
              'Контакты',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.all(20.0),
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///ФИО
                  if (state is UserGetState && state.getUser[0]['name'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ФИО'),
                        const SizedBox(height: 10.0),
                        Text(
                          '${state.getUser[0]['name']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                  ///Номер телефона
                  if (state is UserGetState && state.getUser[0]['contact_phone'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0),
                        const Text('Номер телефона'),
                        const SizedBox(height: 10.0),
                        Text(
                          '${state.getUser[0]['contact_phone']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                  ///Эл. почта
                  if (state is UserGetState && state.getUser[0]['email'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0),
                        const Text('Эл. почта'),
                        const SizedBox(height: 10.0),
                        Text(
                          '${state.getUser[0]['email']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
