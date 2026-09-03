import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helper/class_colors.dart';
import '../screns/schedule/object/widgets/schedule_offer_dialog.dart';

/// Набросок диалога «Расставить график ТО?» — вид без сервера и без формы
/// создания объекта.
///
/// Кадра на диалог нет, и по правилу «макет утверждается до логики» вид
/// показывается отдельно: форма объекта подрядчика длинная, заполнять её
/// ради одного окна незачем.
///
/// Запуск:
///
///     flutter run -t lib/dev/schedule_offer_preview.dart -d chrome
///
/// В прод-сборку файл не попадает: сборка идёт с `lib/main.dart`, и ничто из
/// приложения на него не ссылается.
void main() {
  runApp(const ScheduleOfferPreviewApp());
}

class ScheduleOfferPreviewApp extends StatelessWidget {
  const ScheduleOfferPreviewApp({Key? key}) : super(key: key);

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
      home: const _OfferPicker(),
    );
  }
}

class _OfferPicker extends StatefulWidget {
  const _OfferPicker({Key? key}) : super(key: key);

  @override
  State<_OfferPicker> createState() => _OfferPickerState();
}

class _OfferPickerState extends State<_OfferPicker> {
  /// Чем кончился прошлый показ — вместо мастера и экрана графика, которых в
  /// наброске нет.
  String? _answer;

  Future<void> _open(String objectName) async {
    final bool? approved = await showScheduleOfferDialog(
      context,
      objectName: objectName,
      year: DateTime.now().year,
    );
    if (!mounted) return;
    setState(() {
      _answer = approved == true
          ? 'Расставить → открылся бы мастер, а после утверждения — экран '
              'графика объекта'
          : 'Позже → остались бы в списке объектов';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: const Text('Предложение расставить график — набросок'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.myColorGreenAuth,
                  foregroundColor: ColorApp.myColorWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                ),
                onPressed: () =>
                    _open('г. Краснодар, ул. Северная, 356'),
                child: const Text('Объект с названием'),
              ),
              const SizedBox(height: 12.0),
              // Название в форме обязательно, но ответ сервера теоретически
              // может прийти без него — окно не должно показывать пустые
              // кавычки.
              TextButton(
                onPressed: () => _open(''),
                child: const Text('Объект без названия'),
              ),
              if (_answer != null) ...<Widget>[
                const SizedBox(height: 24.0),
                Text(
                  _answer!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: ColorApp.myColorGray,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
