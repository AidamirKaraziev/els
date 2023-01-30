import 'package:flutter/material.dart';

///Заявки

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: const [
          Center(child: Text('Заявки')),
        ],
      ),
    );
  }
}
