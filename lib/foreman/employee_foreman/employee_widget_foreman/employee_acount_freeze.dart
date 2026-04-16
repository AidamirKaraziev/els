// import 'package:els/foreman/employee_foreman/employee_page_foreman.dart';
// import 'package:flutter/material.dart';
// import '../../../helper/class_colors.dart';
// import '../../../screns/home_page/home_page.dart';
//
// /// Заморозка Юзера
//
// class EmployeeAccountFreezeForeman extends StatelessWidget {
//   const EmployeeAccountFreezeForeman({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20.0),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Spacer(),
//               IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.close,
//                     color: ColorApp.myColorGreenAuth,
//                   )),
//             ],
//           ),
//           const SizedBox(height: 10.0),
//           const Text(
//             'Заморозка аккаунта',
//             style:
//             TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 20.0),
//           const Text(
//             'Вы действительно хотите заморозить аккаунт?',
//             style:
//             TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
//           ),
//           const SizedBox(height: 10.0),
//           Text(
//             ' ${String.fromCharCode(0x2022)} Пользователь больше не сможет входить в систему',
//             style:  const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
//           ),
//           const SizedBox(height: 10.0),
//           Text(
//             ' ${String.fromCharCode(0x2022)} Аккаунт можно будет разморозить',
//             style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
//           ),
//           const SizedBox(height: 20.0),
//           Row(
//             children: [
//               ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: const Size(100.0, 40.0),
//                     primary: ColorApp.myColorGrayText,
//                     onPrimary: ColorApp.myColorBlack,
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   }, child: const Text('Отмена', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
//               const SizedBox(width: 10.0),
//               ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       minimumSize: const Size(200.0, 40.0),
//                       primary: ColorApp.myColorGreenAuth
//                   ),
//                   onPressed: () async {
//                     await freezingEmployeeForeman(IntTest.pressHover);
//                     myStream.add(IntTest.indexScreensForeman);
//                     // ignore: use_build_context_synchronously
//                     Navigator.pop(context);
//                   }, child: const Text('Подтвердить', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }