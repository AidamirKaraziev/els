import 'package:flutter/material.dart';
import '../../../bloc/company_bloc/company_bloc.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../view/companies_screen.dart';
import '../view/companies_screen_archive.dart';
import '../view/company_page.dart';

/// Заморозка Компании =================================
class CompanyAccountFreeze extends StatelessWidget {
  const CompanyAccountFreeze({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    foregroundColor: ColorApp.myColorBlack, backgroundColor: ColorApp.myColorGrayText, minimumSize: const Size(100.0, 40.0),
                  ),
                  onPressed: (){
                    Navigator.pop(context);
                  }, child: const Text('Отмена', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
              const SizedBox(width: 10.0),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200.0, 40.0), backgroundColor: ColorApp.myColorGreenAuth
                  ),
                  onPressed: () async {
                    await freezingCompany(IntTest.pressHover);
                    CompanyBloc().add(CompanyGetUserEvent());
                    await getCompanyArchive();
                    myStream.add(IntTest.indexScreens);
                    Navigator.pop(context);
                  }, child: const Text('Подтвердить', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
            ],
          ),
        ],
      ),
    );
  }
}
/// ====================================================