import 'package:flutter/material.dart';

///Графики

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          Center(child: Text('Графики')),
        ],
      ),
    );
  }
}
