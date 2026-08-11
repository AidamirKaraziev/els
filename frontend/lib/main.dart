import 'package:els/screns/auth/auth.dart';
import 'package:els/screns/employee/bloc/employee_bloc.dart';
import 'package:els/screns/object/bloc/object_bloc.dart';
import 'package:els/screns/task/bloc_task/task_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bloc/company_bloc/company_bloc.dart';
import 'bloc/user_bloc/user_bloc.dart';
import 'package:google_fonts/google_fonts.dart';






void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EmployeeBloc>(create: (context) => EmployeeBloc()..add(EmployeeGetUserEvent())),
        BlocProvider<CompanyBloc>(create: (context) => CompanyBloc()..add(CompanyGetUserEvent())),
        BlocProvider<UserBloc>(create: (context) => UserBloc()..add(UserGetEvent())),
        BlocProvider<MyObjectBloc>(create: (context) => MyObjectBloc()..add(ObjectGetEvent())),
        BlocProvider<TaskBloc>(create: (context) => TaskBloc()..add(TaskGetEvent())),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', ''),
        ],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.ubuntuTextTheme(),
        ),
        home: const Auth(),
      ),
    );
  }
}
