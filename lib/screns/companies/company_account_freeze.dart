import 'package:els/helper/class_colors.dart';
import 'package:flutter/material.dart';

class CompanyAccountFreeze extends StatelessWidget {
  const CompanyAccountFreeze({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: ColorApp.myColorGreenAuth,
                  )),
            ],
          ),
          const SizedBox(height: 10.0),
          const Text(
            'Заморозка аккаунта компании',
            style:
            TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20.0),
          const Text(
            'Вы действительно хотите заморозить аккаунт?',
            style:
            TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 10.0),
           Text(
            ' ${String.fromCharCode(0x2022)} Пользователи этой компании больше не смогут входить в систему',
            style:  const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 10.0),
          Text(
            ' ${String.fromCharCode(0x2022)} Компанию можно будет разморозить',
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100.0, 40.0),
                      primary: ColorApp.myColorGrayText,
                    onPrimary: ColorApp.myColorBlack,
                  ),
                  onPressed: (){}, child: const Text('Отмена', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
              const SizedBox(width: 10.0),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200.0, 40.0),
                    primary: ColorApp.myColorGreenAuth
                  ),
                  onPressed: (){}, child: const Text('Подтвердить', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
            ],
          ),
        ],
      ),
    );
  }
}
