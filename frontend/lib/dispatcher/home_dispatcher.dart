import 'package:els/dispatcher/drawer_dispatcher.dart';
import 'package:els/dispatcher/task_screen_dispatcher/application_page.dart';
import 'package:els/dispatcher/task_screen_dispatcher/application_page_completed.dart';
import 'package:els/dispatcher/task_screen_dispatcher/application_screen.dart';
import 'package:els/dispatcher/task_screen_dispatcher/application_screen_completed.dart';
import 'package:els/dispatcher/user_page_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/user_bloc/user_bloc.dart';
import '../helper/class_colors.dart';
import '../helper/header/header.dart';
import '../screns/home_page/home_page.dart';

/// Домашняя Dispatcher

class HomeDispatcher extends StatefulWidget {
  const HomeDispatcher({Key? key}) : super(key: key);

  @override
  State<HomeDispatcher> createState() => _HomeDispatcherState();
}

class _HomeDispatcherState extends State<HomeDispatcher> {
  ///Список Страниц
  final List<Widget> _screensDispatcher = [
    /// Список Заявок 0
    const ApplicationScreen(),

    /// Выбранная заявка 1
    const ApplicationPage(),

    /// Список выполненых Заявок 2
    const ApplicationScreenCompleted(),

    /// Выбранная выполненая заявка 3
    const ApplicationPageCompleted(),

    /// Окно User 4
    const OpenViewUserDispatcher(),
  ];

  @override
  void initState() {

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ///Боковое меню
                    if (size.width > 1350)
                       const Expanded(
                        flex: 2,
                        child: DrawerDispatcher(),
                      ),
                    /// Body
                    Expanded(
                      flex: 8,
                      child: Column(
                        children: [
                          /// Body
                          StreamBuilder(
                            stream: myStream.stream,
                            builder: (context, ind) => Expanded(
                              flex: 9,
                              child: _screensDispatcher[IntTest.indexScreensDispatcher],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
