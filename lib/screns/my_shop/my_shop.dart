import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Мой магазин (Временно)

class MyShop extends StatefulWidget {
  const MyShop({Key? key}) : super(key: key);

  @override
  State<MyShop> createState() => _MyShopState();
}

final Uri myUrl = Uri.parse('https://www.youtube.com/');

class _MyShopState extends State<MyShop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: GridView.count(
            crossAxisCount: 5,
            children: [
              /// Ютуб
                MyShopWidget(
                name: 'Ютуб',
                image:
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR4fRD0F0vxs967BpnjSlJAwJHWLuZ-1hmuagiyoNudXomo5Ax7uBY-qK0P-pL0Q4ulhqI&usqp=CAU',
                getLinkNetwork: '$myUrl',
              ),
              /// Наш Сайт
              const MyShopWidget(
                name: 'Наш Сайт',
                image:
                    'https://cdn-icons-png.flaticon.com/512/2197/2197303.png',
                getLinkNetwork: 'https://plk-krd.ru/',
              ),
              const MyShopWidget(
                name: 'Запчасти',
                image:
                    'https://thumbs.dreamstime.com/b/%D0%BD%D0%B0%D0%B1%D0%BE%D1%80-%D0%B2%D0%B5%D0%BA%D1%82%D0%BE%D1%80%D0%BD%D1%8B%D1%85-%D0%B8%D0%BA%D0%BE%D0%BD%D0%BE%D0%BA-%D0%B7%D0%B0%D0%BF%D1%87%D0%B0%D1%81%D1%82%D0%B5%D0%B9-%D0%B0%D0%B2%D1%82%D0%BE%D0%BC%D0%BE%D0%B1%D0%B8%D0%BB%D1%8F-%D1%81%D0%BE%D0%B2%D1%80%D0%B5%D0%BC%D0%B5%D0%BD%D0%BD%D0%B0%D1%8F-%D1%81%D0%B1%D0%BE%D1%80%D0%BA%D0%B0-165273461.jpg',
                getLinkNetwork: 'https://zaplift.ru/',
              ),
              /// Написать в Ват Сап
              const MyShopWidget(
                  name: 'Написать в Ват Сап',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/3536/3536445.png',
                  getLinkNetwork: 'https://wa.me/79890902801',
              ),
              /// Написать в Телеграм
              const MyShopWidget(
                  name: 'Написать в Телеграм',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/2111/2111646.png',
                  getLinkNetwork: 'https://t.me/vovahcosv',
              ),
              /// Позвонить Вове
              const MyShopWidget(
                  name: 'Позвонить Вове',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/3636/3636151.png',
                  getLinkNetwork: 'tel://89890902801',
              ),
              /// Ютуб
              const MyShopWidget(
                name: 'Ютуб',
                image:
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR4fRD0F0vxs967BpnjSlJAwJHWLuZ-1hmuagiyoNudXomo5Ax7uBY-qK0P-pL0Q4ulhqI&usqp=CAU',
                getLinkNetwork: 'https://www.youtube.com/',
              ),
              /// Наш Сайт
              const MyShopWidget(
                  name: 'Наш Сайт',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/2197/2197303.png',
                  getLinkNetwork: 'https://plk-krd.ru/',
              ),
              const MyShopWidget(
                  name: 'Запчасти',
                  image:
                  'https://thumbs.dreamstime.com/b/%D0%BD%D0%B0%D0%B1%D0%BE%D1%80-%D0%B2%D0%B5%D0%BA%D1%82%D0%BE%D1%80%D0%BD%D1%8B%D1%85-%D0%B8%D0%BA%D0%BE%D0%BD%D0%BE%D0%BA-%D0%B7%D0%B0%D0%BF%D1%87%D0%B0%D1%81%D1%82%D0%B5%D0%B9-%D0%B0%D0%B2%D1%82%D0%BE%D0%BC%D0%BE%D0%B1%D0%B8%D0%BB%D1%8F-%D1%81%D0%BE%D0%B2%D1%80%D0%B5%D0%BC%D0%B5%D0%BD%D0%BD%D0%B0%D1%8F-%D1%81%D0%B1%D0%BE%D1%80%D0%BA%D0%B0-165273461.jpg',
                  getLinkNetwork: 'https://zaplift.ru/',
              ),
              /// Написать в Ват Сап
              const MyShopWidget(
                name: 'Написать в Ват Сап',
                image:
                'https://cdn-icons-png.flaticon.com/512/3536/3536445.png',
                getLinkNetwork: 'https://wa.me/79890902801',

              ),
              /// Написать в Телеграм
              const MyShopWidget(
                  name: 'Написать в Телеграм',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/2111/2111646.png',
                  getLinkNetwork: 'https://t.me/vovahcosv',
              ),
              /// Позвонить Вове
              const MyShopWidget(
                  name: 'Позвонить Вове',
                  image:
                  'https://cdn-icons-png.flaticon.com/512/3636/3636151.png',
                  getLinkNetwork: 'tel://89890902801',
              ),
            ],
          ),
        ));
  }
}

class MyShopWidget extends StatelessWidget {
  const MyShopWidget({
    super.key,
    required this.getLinkNetwork,
    required this.name,
    required this.image,
  });

  final String getLinkNetwork;
  final String name;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0,top: 20.0,right: 10),
      child: GestureDetector(
        onTap: () => launch(getLinkNetwork),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                image,
                fit: BoxFit.cover,
                width: 100.0,
                height: 100.0,
              ),
              const SizedBox(height: 10.0),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
