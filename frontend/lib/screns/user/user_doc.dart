import 'package:dotted_border/dotted_border.dart';
import 'package:els/screns/user/user_contact.dart';
import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import '../home_page/home_page.dart';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/api_image.dart';

///Блок User Doc

class UserDoc extends StatelessWidget {
  const UserDoc({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: myStream.stream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Документы',
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
                child: Row(
                  children: [
                    /// Удостоверение
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // await openGalleryDocUserCertificate();
                          // setState(() {});
                          myStream.add(IntTest.indexScreens);
                          // setState(() {
                          //   showDialog(
                          //       context: context,
                          //       builder: (context) =>
                          //           const AlertDialog(content: WorksPhotoDocUdo()));
                          // });
                        },
                        child: userProfile[0]['identity_card'] == null
                            ? const DottedBorder(
                          // radius: Radius.circular(20.0),
                          // color: ColorApp.myColorGray,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              // crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.backup, color: ColorApp.myColorGrayText, size: 30.0),
                                SizedBox(height: 10.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Добавить фото\nудостоверения',
                                        style: TextStyle(
                                            fontSize:
                                            16.0,
                                            color: ColorApp
                                                .myColorGrayText)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                            : apiImageWidget(userProfile[0]['identity_card']),
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    /// ЦОК
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // await openGalleryDocUserQualifications();
                          // myStream.add(IntTest.indexScreens);
                          // setState(() {});

                          // setState(() {
                          //   showDialog(
                          //       context: context,
                          //       builder: (context) =>
                          //           const AlertDialog(
                          //             content:
                          //                 WorksPhotoDoc(),
                          //           ));
                          // });
                        },
                        child: userProfile[0]['qualification_file'] == null
                            ? const DottedBorder(
                          // radius: Radius.circular(20.0),
                          // color: ColorApp.myColorGray,
                          child: Center(
                            child: Padding(padding: EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.backup, color: ColorApp.myColorGrayText,size: 30.0),
                                  SizedBox(height: 10.0),
                                  Text(
                                    'Добавить фото\nЦОК',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: ColorApp
                                            .myColorGrayText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : StreamBuilder(
                          stream:
                          myStreamPhotoDoc.stream,
                          builder: (BuildContext
                          context,
                              AsyncSnapshot<dynamic>
                              snapshot) {
                            return apiImageWidget(userProfile[0]['qualification_file']);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
