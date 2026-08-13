import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:els/screns/user/user_contact.dart';
import 'package:els/screns/user/widgets/editing_profile.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:els/helper/image_picking.dart';
import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/class_colors.dart';
import '../employee/view/employees_screen.dart';
import '../home_page/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';


/// Блок User Profile

String newPhoto = '';
String newPhotoSelectEmployee = '';
String addPhotoSelectEmployee = '';

class UserProfile extends StatefulWidget {
  const UserProfile({
    Key? key,
  }) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {


  /// Функция изменение фото ====================
  var imagePath;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGallery() async {
    if (kIsWeb) {
      PickedImage? imageFile = (await pickImageFromGallery());
      if (imageFile != null) {
        imagePath = imageFile;
        // print(imagePath);
        requestHttp(imageFile);
      }
    }
  }
  requestHttp(PickedImage imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse(
        "${ApiConfig.base}/cp/universal-user/me/photo/");
    http.MultipartRequest request = await Api.multipart("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await Api.sendMultipart(request);
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      userProfile[0]['photo'] = listTestPhoto['data']['photo'];
      dataEmployee[IntTest.indexUserList]['photo'] = listTestPhoto['data']['photo'];
      UserBloc().add(UserGetEvent());
    });
    myStream.add(IntTest.indexScreens);
  }
  /// ============================================


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: myStream.stream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Текс Профиль
              const Text(
                'Профиль',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20.0),
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Фото сотрудника
                      Badge(
                          smallSize: 30.0,
                          largeSize: 50.0,
                          alignment: const AlignmentDirectional(100, 90),
                          backgroundColor: ColorApp.myColorGreen,
                          label: IconButton(
                              onPressed: () async {
                                await openGallery();
                                myStream.add(IntTest.indexScreens);
                              },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: ColorApp.myColorWhite,
                              )),
                          child: CircleAvatar(
                            radius: 70.0,
                            backgroundImage: const AssetImage('assets/user.png'),
                            foregroundImage: newPhoto != ''
                                ? apiImage(newPhoto)
                                : apiImage(userProfile[0]['photo']),
                          )),
                      const SizedBox(height: 10.0),
                      /// Имя сотрудника
                      Center(
                        child: Text(
                            userProfile[0]['name'] != null
                                ? '${userProfile[0]['name']}'
                                : '',
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
                          onPressed: () {
                            setState(() {
                              showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                        content: EditingProfile(),
                                      )).then((value) => setState(() {}));
                            });
                          },
                          child: Text('Редактировать',
                              style: TextStyle(
                                  fontSize: 10.0, color: Colors.grey.shade400))),
                    ],
                  ),
                ),
              )
            ],
          );
        });
  }
}
