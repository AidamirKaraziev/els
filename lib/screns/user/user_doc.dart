import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../../helper/class_colors.dart';

///Блок User Doc

class UserDoc extends StatelessWidget {
  const UserDoc({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Документы',style: TextStyle(fontWeight: FontWeight.w600),),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Документ'),
                        SizedBox(height: 10.0),
                        Text('Удостоверение',style: TextStyle(fontWeight: FontWeight.w600),),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: GestureDetector(
                        onTap: () async {
                          final imageClassification =
                          await ImagePickerWeb.getImageAsBytes();
                        },
                        child: DottedBorder(
                          color: ColorApp.myColorGray,
                          child: const SizedBox(
                            height: 44.0,
                            child: Center(
                              child: Icon(Icons.backup_outlined,
                                  color: ColorApp.myColorGray),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Документ'),
                        SizedBox(height: 10.0),
                        Text('ЦОК',style: TextStyle(fontWeight: FontWeight.w600),),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final imageClassification =
                        await ImagePickerWeb.getImageAsBytes();
                      },
                      child: DottedBorder(
                        color: ColorApp.myColorGray,
                        child: const SizedBox(
                          height: 44.0,
                          child: Center(
                            child: Icon(Icons.backup_outlined,
                                color: ColorApp.myColorGray),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}