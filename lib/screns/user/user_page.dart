import 'package:els/screns/user/user_contact.dart';
import 'package:els/screns/user/user_doc.dart';
import 'package:els/screns/user/user_info.dart';
import 'package:els/screns/user/user_profile.dart';
import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';


///Мой профиль

class UserPage extends StatefulWidget {
  const UserPage({Key? key,}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      color: ColorApp.myColorTransparent,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (size.width > 600) Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: const [
                      UserProfile(),
                      SizedBox(width: 20.0),
                      Expanded(child: UserInfo()),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: const [
                      Expanded(child: UserContact()),
                      SizedBox(width: 20.0),
                      Expanded(child: UserDoc()),
                    ],
                  ),
                ],
              ),
            ) else Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  UserProfile(),
                  SizedBox(height: 20.0),
                  UserInfo(),
                  SizedBox(height: 20.0),
                  UserContact(),
                  SizedBox(height: 20.0),
                  UserDoc(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
