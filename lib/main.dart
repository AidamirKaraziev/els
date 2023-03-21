import 'package:els/bloc/object_bloc/object_bloc.dart';
import 'package:els/screns/auth/auth.dart';
import 'package:els/screns/employee/bloc/employee_bloc.dart';
import 'package:els/screns/object/bloc/object_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bloc/company_bloc/company_bloc.dart';
import 'bloc/user_bloc/user_bloc.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final employeeBloc = EmployeeBloc();
    final companyBloc = CompanyBloc();
    final userBloc = UserBloc();
    final myObjectBloc = MyObjectBloc();
    return MultiBlocProvider(
      providers: [
        BlocProvider<EmployeeBloc>(create: (context) => employeeBloc..add(EmployeeGetUserEvent())),
        BlocProvider<CompanyBloc>(create: (context) => companyBloc..add(CompanyGetUserEvent())),
        BlocProvider<UserBloc>(create: (context) => userBloc..add(UserGetEvent())),
        BlocProvider<MyObjectBloc>(create: (context) => myObjectBloc..add(ObjectGetEvent())),
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
        home:
        const Auth(),
      ),
    );
  }
}
