// ignore_for_file: avoid_returning_null_for_void, library_private_types_in_public_api

import 'dart:html';

import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'dart:html' as html;
import 'package:path/path.dart' as Path;


// final uri = Uri.parse('https://myendpoint.com');
// var request = new http.MultipartRequest('POST', uri);
// final httpImage = http.MultipartFile.fromBytes('files.myimage', bytes,
//     contentType: MediaType.parse(mimeType), filename: 'myImage.png');
// request.files.add(httpImage);
// final response = await request.send();



const Color kDarkGray = Color(0xFFA3A3A3);
const Color kLightGray = Color(0xFFF1F0F5);
File ? image;

class PhotosHistoryAddPage extends StatelessWidget {
  const PhotosHistoryAddPage({super.key});

  @override
  Widget build(BuildContext context) => const ImagePickerWidget();
}

enum PageStatus { loading, error, loaded }

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {

  // html.File _cloudFile;
  // var _fileBytes;
  // Image _imageWidget;
  //
  // Future<void> getMultipleImageInfos() async {
  //   var mediaData = await ImagePickerWeb.getImageInfo;
  //   String mimeType = mime(Path.basename(mediaData.fileName));
  //   html.File mediaFile =
  //   new html.File(mediaData.data, mediaData.fileName, {'type': mimeType});
  //
  //   if (mediaFile != null) {
  //     setState(() {
  //       _cloudFile = mediaFile;
  //       _fileBytes = mediaData.data;
  //       _imageWidget = Image.memory(mediaData.data);
  //     });
  //   }
  // }

  final _photos = <Image>[];
  PageStatus _pageStatus = PageStatus.loaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Загрузка фото')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddPhoto();
                }
                // image = _photos[index - 1];
                return Stack(
                  children: <Widget>[
                    // InkWell(
                    //   child: Container(
                    //       margin: const EdgeInsets.all(5),
                    //       height: 100,
                    //       width: 100,
                    //       child: image),
                    // ),
                  ],
                );
              },
            ),
          ),
          // if (_pageStatus == PageStatus.loaded)
            Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  print(image);
                  // File? image = (await ImagePickerWeb.getMultiImagesAsFile())?[0];
                },
                child: const Text('Сохранить'),
              ),
            ),
        ],
      ),
    );
  }

  InkWell _buildAddPhoto() {
    if (_pageStatus == PageStatus.loading) {
      return InkWell(
        onTap: () => null,
        child: Container(
          margin: const EdgeInsets.all(5),
          height: 100,
          width: 100,
          color: kDarkGray,
          child: const Center(child: Text('Загружаю...')),
        ),
      );
    } else {
      return InkWell(
        onTap: () => _onAddPhotoClicked(context),
        child: Container(
          margin: const EdgeInsets.all(5),
          height: 100,
          width: 100,
          color: kDarkGray,
          child: const Center(
            child: Icon(
              Icons.add_to_photos,
              color: kLightGray,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onAddPhotoClicked(context) async {
    setState(() {
      _pageStatus = PageStatus.loading;
    });

    File? imageFile = (await ImagePickerWeb.getMultiImagesAsFile())?[0];
    // final image = await ImagePickerWeb.getImageAsFile();
    print(imageFile!.relativePath);

    if (image != null) {
      setState(() {
        _photos.add(image as Image);
        _pageStatus = PageStatus.loaded;
      });
    } else {
      setState(() {
        _pageStatus = PageStatus.loaded;
      });
    }
  }
}