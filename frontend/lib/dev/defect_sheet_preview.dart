import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../helper/image_picking.dart';
import '../mechanic/screens/defect_sheet.dart';

/// Набросок листа «Дефект» — вид без сервера и без входа в приложение.
///
/// Кадра на форму дефекта в макете нет, и по правилу «макет утверждается до
/// логики» вид показывается отдельно: чтобы дойти до листа в самом
/// приложении, надо войти механиком, взять ТО в работу и иметь под рукой
/// боевые данные.
///
/// Снимок здесь подставной: камеры в браузере на превью нет, а строка
/// превью-картинок — часть вида, которую и надо посмотреть.
///
/// Запуск:
///
///     flutter run -t lib/dev/defect_sheet_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const DefectSheetPreviewApp());
}

class DefectSheetPreviewApp extends StatelessWidget {
  const DefectSheetPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('ru', '')],
      theme: ThemeData(textTheme: GoogleFonts.ubuntuTextTheme()),
      home: const _DefectPicker(),
    );
  }
}

class _DefectPicker extends StatefulWidget {
  const _DefectPicker({Key? key}) : super(key: key);

  @override
  State<_DefectPicker> createState() => _DefectPickerState();
}

class _DefectPickerState extends State<_DefectPicker> {
  /// Чем кончился прошлый показ — вместо очереди и сервера, которых в
  /// наброске нет.
  String? _answer;

  @override
  void initState() {
    super.initState();
    // Лист открывается сам: превью смотрят ради него, а нажатие на кнопку
    // до Flutter-канвы из отладчика браузера не доходит — известный долг.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final DefectDraft? draft = await showDefectSheet(
      context,
      pickPhoto: _fakePhoto,
    );
    if (!mounted) return;
    setState(() {
      _answer = draft == null
          ? 'Механик закрыл лист, ничего не записав.'
          : 'Дефект «${draft.title}»'
              '${draft.description == null ? '' : ', подробности: ${draft.description}'}'
              ', снимков: ${draft.photos.length}.';
    });
  }

  /// Однотонный квадрат вместо снимка: в превью нужен размер и форма
  /// картинки, а не её содержимое.
  Future<PickedImage?> _fakePhoto({required bool fromCamera}) async {
    return PickedImage(fileName: 'shot.png', data: _square());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorWhite,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Набросок листа «Дефект»',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _open,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.myColorGreenAuth,
                  foregroundColor: ColorApp.myColorWhite,
                ),
                child: const Text('Записать дефект'),
              ),
              const SizedBox(height: 16.0),
              if (_answer != null)
                Text(
                  _answer!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Серый квадрат 8×8 в PNG — подставной снимок.
Uint8List _square() {
  return Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x08,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x4B, 0x6D, 0x29, 0xDC, 0x00, 0x00, 0x00,
    0x11, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x98, 0x3D, 0x6B, 0x16,
    0x56, 0xC4, 0x30, 0xB4, 0x24, 0x00, 0x3A, 0xAB, 0x73, 0xC1, 0x0A, 0xC4,
    0x5F, 0x93, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ]);
}
