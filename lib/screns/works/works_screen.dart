import 'package:flutter/material.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:http/http.dart' as http;

///Охрана труда

class WorksScreen extends StatefulWidget {
  const WorksScreen({Key? key}) : super(key: key);

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

final List newsList = [];

getHttpNews() async {
  var response = await http.get(Uri.parse('https://habr.com/ru/rss/hubs/all/'));
  var chanel = RssFeed.parse(response.body);
  for (var element in chanel.items!) {
    newsList.add(element);
  }
  return newsList;
}


class _WorksScreenState extends State<WorksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder(
          future: getHttpNews(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: newsList.length,
                itemExtent: 50.0,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text('${newsList[index].title}'),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}