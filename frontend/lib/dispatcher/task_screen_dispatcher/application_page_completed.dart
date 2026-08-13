import 'package:els/dispatcher/user_page_dispatcher.dart';
import 'package:els/foreman/task_foreman/task_screen_foreman.dart';
import 'package:els/screns/task/view/task_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../helper/class_colors.dart';
import '../../../screns/home_page/home_page.dart';
import '../../../screns/object/view/object_page.dart';
import '../../../screns/user/user_contact.dart';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/api_image.dart';

/// Выбранная выполненная заявка

class ApplicationPageCompleted extends StatefulWidget {
  const ApplicationPageCompleted({Key? key}) : super(key: key);

  @override
  State<ApplicationPageCompleted> createState() => _ApplicationPageCompletedState();
}

class _ApplicationPageCompletedState extends State<ApplicationPageCompleted> {

  DateTime newDateTasks = DateTime.now();

  @override
  void dispose() {
    photoSelectedTaskIdForeman.clear();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewTaskPage = listSelectedTaskIdForeman['data'];
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          backgroundColor: ColorApp.myColorTransparent,
          body: SingleChildScrollView(
            child: Column(
              children: [
                ///Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:ColorApp.kPadding),
                  color: Colors.white,
                  height: 70,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      /// Кнопка назад в задачи
                      Row(
                        children: [
                          Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: ColorApp.myColorAvatar,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    IntTest.indexScreensDispatcher = 2;
                                    myStream.add(IntTest.indexScreensDispatcher);
                                  });
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.black,size: 13.0,
                                )),
                          ),
                          const SizedBox(width: 30.0),
                        ],
                      ),
                      ///Text
                      Text('Заявка',
                          style: TextStyle(
                              fontSize: size.width > 350
                                  ? 25.0
                                  : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      Row(
                        children: const [
                          SizedBox(width: 10.0),
                          /// Изменить
                          // IconButton(
                          //     onPressed: () {
                          //       setState(() {
                          //         showDialog(
                          //             context: context,
                          //             builder: (context) =>
                          //                 AlertDialog(
                          //                   content: EditingTaskForeman(),
                          //                 ));
                          //       });
                          //     },
                          //     icon: const Icon(
                          //         Icons.edit_outlined,
                          //         color: ColorApp
                          //             .myColorGreenAuth)),
                        ],
                      ),
                      const Spacer(),
                      ///Колокольчик
                      // if (size.width > 400)
                      //   Badge(
                      //     alignment:
                      //     const AlignmentDirectional(21, 4),
                      //     backgroundColor: ColorApp.myColorRed,
                      //     isLabelVisible: IntTest.badgeCount > 0
                      //         ? true
                      //         : false,
                      //     label: IntTest.badgeCount < 1
                      //         ? const SizedBox.shrink()
                      //         : Text(
                      //         IntTest.badgeCount.toString(),
                      //         style: const TextStyle(
                      //             fontSize: 12.0,
                      //             color:
                      //             ColorApp.myColorWhite,
                      //             fontWeight:
                      //             FontWeight.w500)),
                      //     child: IconButton(
                      //       onPressed: () {},
                      //       icon: const Icon(
                      //           Icons
                      //               .notifications_none_outlined,
                      //           size: 25.0),
                      //     ),
                      //   ),
                      // SizedBox(width: size.width > 500 ? 40.0 : 10.0),
                      ///Аватар Юзера
                      const MyUserDispatcher(),
                    ],
                  ),
                ),
                ///Задача
                Padding(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Задача',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius:
                          BorderRadius.circular(5.0),
                          color: viewTaskPage['status_id']['id'] == 3 ? Colors.yellow[50] : viewTaskPage['status_id']['id'] == 4 ? Colors.green[50] : viewTaskPage['status_id']['id'] == 5 ? Colors.red[300] : ColorApp.myColorWhite,
                          boxShadow:  const [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: size.width > 850
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// Дата заявки, Автор задачи, Назначенный исполнитель
                            Column(
                              children: [
                                /// Дата заявки
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons.calendar_month_outlined,
                                        title: 'Дата заявки',
                                        subtitle: DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(viewTaskPage['created_at']*1000)) ?? '')),
                                /// Автор задачи исправить
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons
                                            .support_agent_outlined,
                                        title:
                                        'Автор задачи',
                                        subtitle:
                                        '${userProfile[0]['name']}' ?? '')),
                                /// Назначенный исполнитель
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons.person_outline,
                                        title: 'Назначенный исполнитель',
                                        subtitle: viewTaskPage['executor_id'] == null ? '' :
                                        '${viewTaskPage['executor_id']['name']}' ?? '')),
                              ],
                            ),
                            /// Срок исполнения, Объект, Задача
                            Column(
                              children: [
                                /// Срок исполнения до
                                Expanded(
                                    child: IconAndText(
                                      icon: Icons.calendar_month_outlined,
                                      title: 'Срок исполнения',
                                      subtitle: '${newDateTasks.day} - ${newDateTasks.month} - ${newDateTasks.year}',
                                      // 'до ${viewTaskPage['fault_category_id']['task_text']}' ?? '')
                                    )),

                                /// Объект
                                viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.home_work_outlined,
                                        title: 'Объект',
                                        subtitle: viewTaskPage['object_id']['name'].toString() ?? '')),

                                /// Задача
                                viewTaskPage['task_text'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.build_circle_outlined,
                                        title: 'Задача',
                                        subtitle: '${viewTaskPage['task_text']}' ?? '')),

                              ],
                            ),
                            /// Категория неисправности, Фото, Назначенный исполнитель
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Статус
                                viewTaskPage['status_id']['id'] == null ? const Text('') :  Expanded(
                                    child: IconAndText(
                                        icon: Icons.run_circle_outlined,
                                        title: 'Статус',
                                        subtitle:
                                        '${viewTaskPage['status_id']['name']}' ?? '')),
                                /// Участок
                                viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.domain,
                                        title: 'Участок',
                                        subtitle:
                                        '${viewTaskPage['object_id']['division_id']['title']}' ?? '')),
                                /// Адрес
                                viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.place_outlined,
                                        title: 'Адрес',
                                        subtitle:
                                        '${viewTaskPage['object_id']['address']}' ?? '')),
                              ],
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// Дата заявки, Объект, Адрес, Автор задачи, Назначенный исполнитель
                            Column(
                              children: [
                                /// Дата заявки
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons.calendar_month_outlined,
                                        title: 'Дата заявки',
                                        subtitle: DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(viewTaskPage['created_at']*1000)) ?? '')),
                                /// Объект
                                viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.home_work_outlined,
                                        title: 'Объект',
                                        subtitle: viewTaskPage['object_id']['name'].toString() ?? '')),
                                /// Автор задачи исправить
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons
                                            .support_agent_outlined,
                                        title:
                                        'Автор задачи',
                                        subtitle:
                                        '${userProfile[0]['name']}' ?? '')),
                                /// Задача
                                viewTaskPage['task_text'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.build_circle_outlined,
                                        title: 'Задача',
                                        subtitle: '${viewTaskPage['task_text']}' ?? '')),
                              ],
                            ),
                            /// Срок исполнения, Задача, Статус, Участок
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Срок исполнения до
                                Expanded(
                                    child: IconAndText(
                                      icon: Icons.calendar_month_outlined,
                                      title: 'Срок исполнения',
                                      subtitle: '${newDateTasks.day} - ${newDateTasks.month} - ${newDateTasks.year}',
                                      // 'до ${viewTaskPage['fault_category_id']['task_text']}' ?? '')
                                    )),
                                /// Адрес
                                viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                    child: IconAndText(
                                        icon: Icons.place_outlined,
                                        title: 'Адрес',
                                        subtitle:
                                        '${viewTaskPage['object_id']['address']}' ?? '')),
                                /// Назначенный исполнитель
                                Expanded(
                                    child: IconAndText(
                                        icon: Icons.person_outline,
                                        title: 'Назначенный исполнитель',
                                        subtitle: viewTaskPage['executor_id'] == null ? '' :
                                        '${viewTaskPage['executor_id']['name']}' ?? '')),
                                /// Статус
                                viewTaskPage['status_id']['id'] == null ? const Text('') :  Expanded(
                                    child: IconAndText(
                                        icon: Icons.run_circle_outlined,
                                        title: 'Статус',
                                        subtitle:
                                        '${viewTaskPage['status_id']['name']}' ?? '')),

                                /// Участок
                                // viewTaskPage['object_id'] == null ? const Text('') : Expanded(
                                //     child: IconAndText(
                                //         icon: Icons.domain,
                                //         title: 'Участок',
                                //         subtitle:
                                //         '${viewTaskPage['object_id']['division_id']['title']}' ?? '')),

                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20.0),
                          /// Коментарий к задаче
                          if(viewTaskPage['commentary'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20.0),
                                const Text('Коментарий',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 20.0),
                                Container(
                                  padding: const EdgeInsets.all(10.0),
                                  height: 100.0,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: Text('${viewTaskPage['commentary']}'),
                                ),
                              ],
                            ),
                          const SizedBox(width: 20.0),
                          /// Фото к задаче
                          if(photoSelectedTaskIdForeman.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20.0),
                                const Text('Фото задачи',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 20.0),
                                SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    // controller: employeeScrollController,
                                    itemCount: photoSelectedTaskIdForeman.length,
                                    itemBuilder: (context, index) {
                                      final photoTask = photoSelectedTaskIdForeman[index];
                                      return InkWell(
                                        onTap: () async {
                                          await getPhotoTaskSelected(photoTask['id']);
                                          setState(() {
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                      content: Stack(children: [
                                                        apiImageWidget(onePhotoSelectedTaskId,fit: BoxFit.cover),
                                                        Positioned(
                                                            top: 0,
                                                            right: 0,
                                                            child: IconButton(onPressed: (){Navigator.pop(context);},icon: Icon(Icons.close,color: Colors.red))),

                                                      ]),
                                                    ));
                                          });
                                        },
                                        child: Container(
                                            padding: const EdgeInsets.only(right: 20.0),
                                            width: 230,
                                            height: 230,
                                            child: apiImageWidget(photoTask['photo'],fit: BoxFit.cover)
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],),
          ),
        );
      },
    );

  }
}
