import 'package:flutter/material.dart';

import '../app_download/app_download_screen.dart';
import '../helper/api_client.dart';
import '../helper/session.dart';
import '../helper/splash_screen.dart';
import '../screns/auth/auth.dart';
import 'app_route.dart';
import 'app_section.dart';

/// Стадия приложения: что лежит в основании стопки экранов.
enum AppStage {
  /// Восстанавливаем сессию по refresh-токену — на экране заставка.
  restoring,

  /// Сессии нет — экран входа.
  login,

  /// Вошли — оболочка роли.
  app,
}

/// Маршрутизатор приложения: единственный владелец стопки верхнего уровня.
///
/// Раньше её не было: `MaterialApp(home:)`, `pushAndRemoveUntil` на входе и
/// выходе, а раздел кабинета жил в статике `IntTest.indexScreens*`. На web
/// это значило один адрес на всё приложение и мёртвую кнопку «назад».
///
/// Здесь адрес — это раздел (`/objects`), а стопка — стадия плюс, при нужде,
/// страница скачивания APK поверх. Детальные экраны внутри раздела до S08
/// живут на индексах подрядчика; оболочка сообщает сюда, какому разделу
/// они принадлежат ([showSection]), чтобы адрес и подсветка не отставали.
///
/// Диалоги и экраны, которые подрядчик открывает `Navigator.push`, ложатся
/// поверх страниц как обычные маршруты — навигатор это позволяет.
class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  AppRouterDelegate({this.autoRestore = true});

  /// Восстанавливать ли сессию при первом построении. В тестах — нет.
  final bool autoRestore;

  @override
  GlobalKey<NavigatorState> get navigatorKey => appNavigatorKey;

  AppStage _stage = AppStage.restoring;
  AppStage get stage => _stage;

  /// Открытый раздел; до входа — тот, который просили адресом и который
  /// откроется после входа.
  AppSection _section = AppSection.home;
  AppSection get section => _section;

  /// Открыта ли поверх страница скачивания APK.
  bool _downloadOpen = false;
  bool get downloadOpen => _downloadOpen;

  /// Просили `/app` до входа — открыть после него.
  bool _downloadWanted = false;

  bool _restoreStarted = false;

  /// Стартовый адрес читается платформой до первого построения; здесь
  /// решается, что с ним делать. Дальше — «назад» и адрес, набранный руками.
  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    switch (configuration.kind) {
      case AppRouteKind.login:
        // Адрес входа при живой сессии ничего не значит: человек уже внутри.
        break;
      case AppRouteKind.download:
        // Без сессии страница скачивания ждёт входа: сначала логин, и уже
        // экран входа кладёт её поверх кабинета ([signedIn]).
        if (_stage == AppStage.app) {
          _downloadOpen = true;
        } else {
          _downloadWanted = true;
        }
        break;
      case AppRouteKind.section:
        _downloadOpen = false;
        _section = configuration.section!;
        break;
    }
    // Поверх оболочки мог остаться экран, открытый `Navigator.push`, —
    // раздел меняем под чистой стопкой.
    _popToShell();
    notifyListeners();
  }

  @override
  AppRoutePath? get currentConfiguration {
    if (_downloadOpen) return const AppRoutePath.download();
    if (_stage == AppStage.login) return const AppRoutePath.login();
    return AppRoutePath.section(_section);
  }

  /// Номер последнего тапа по бургеру. Оболочка по нему отличает «человек
  /// нажал раздел» от «адрес сменился под ногами»: первое ведёт к корневому
  /// экрану раздела даже из карточки того же раздела, второе — только если
  /// раздел другой.
  int _tapSerial = 0;
  int get tapSerial => _tapSerial;

  /// Тап по разделу в бургере.
  void goTo(AppSection section) {
    _popToShell();
    _downloadOpen = false;
    _section = section;
    ++_tapSerial;
    notifyListeners();
  }

  /// Оболочка сообщает, к какому разделу относится показанный экран.
  /// Только адрес и подсветка; оболочку это не перестраивает.
  void showSection(AppSection section) {
    if (_section == section) return;
    _section = section;
    notifyListeners();
  }

  /// Вход состоялся: профиль загружен, роль известна.
  void signedIn() {
    _stage = AppStage.app;
    if (!_section.roles.contains(idUserTest)) _section = AppSection.home;
    // Пришли по короткому адресу `els23.ru/app` — за APK, а не в кабинет.
    // Кабинет всё равно кладём под низ: со страницы скачивания человек
    // выходит стрелкой назад и оказывается там, где и ожидает.
    _downloadOpen = openedAtDownloadPage || _downloadWanted;
    _downloadWanted = false;
    notifyListeners();
  }

  /// Сессии больше нет: кнопка выхода или неудачное обновление токена.
  void signedOut() {
    _stage = AppStage.login;
    _section = AppSection.home;
    _popToShell();
    notifyListeners();
  }

  /// Закрыть страницу скачивания APK, вернувшись в кабинет или ко входу.
  void closeDownload() {
    if (!_downloadOpen) return;
    _downloadOpen = false;
    notifyListeners();
  }

  /// «Назад» с платформы: сначала маршруты поверх страниц (диалоги, экраны
  /// подрядчика), потом страница скачивания. Раздел на «назад» не меняется:
  /// в браузере это делает история адресов через [setNewRoutePath].
  @override
  Future<bool> popRoute() async {
    if (await super.popRoute()) return true;
    if (_downloadOpen) {
      closeDownload();
      return true;
    }
    return false;
  }

  void _popToShell() {
    navigatorKey.currentState?.popUntil((Route<dynamic> route) => route.isFirst);
  }

  /// Продолжаем ли прежнюю сессию.
  ///
  /// Access живёт 30 минут, поэтому «войти один раз и работать» держится не
  /// на нём, а на refresh-токене: он лежит на диске, и при запуске мы меняем
  /// его на свежую пару. Без этого перезагрузка вкладки требовала бы пароль.
  /// Без сети обмен не состоится, и это не повод для экрана входа: пара
  /// остаётся на диске, профиль берём из кеша, а шапка покажет «офлайн».
  Future<void> restore() async {
    if (_restoreStarted) return;
    _restoreStarted = true;

    final bool restored = await Api.restoreSession() &&
        await loadProfile(offlineFromCache: true);
    if (!restored) {
      _stage = AppStage.login;
      notifyListeners();
      return;
    }

    markSignedIn();
    signedIn();
    _primeData();
  }

  /// Данные тянем после того, как роль известна: клиенту часть списков
  /// закрыта правами, и спрашивать их незачем. Контекст — навигатора: он
  /// стоит под `MultiBlocProvider` и дотягивается до всех блоков.
  void _primeData() {
    final BuildContext? context = navigatorKey.currentContext;
    if (context != null) primeData(context);
  }

  @override
  Widget build(BuildContext context) {
    if (autoRestore && !_restoreStarted) restore();

    return Navigator(
      key: navigatorKey,
      pages: <Page<void>>[
        switch (_stage) {
          AppStage.restoring =>
            const MaterialPage<void>(key: ValueKey<String>('splash'), child: SplashScreen()),
          AppStage.login =>
            const MaterialPage<void>(key: ValueKey<String>('login'), child: Auth()),
          // Ключ один на сессию: смена раздела оболочку не пересоздаёт —
          // она сама подписана на делегат и меняет экран внутри себя.
          AppStage.app => MaterialPage<void>(
              key: const ValueKey<String>('shell'),
              child: homeScreenForRole(idUserTest),
            ),
        },
        if (_downloadOpen)
          MaterialPage<void>(
            key: const ValueKey<String>('download'),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: AppDownloadScreen(onBack: closeDownload),
              ),
            ),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (page.key == const ValueKey<String>('download')) _downloadOpen = false;
      },
    );
  }
}

/// Один маршрутизатор на приложение — как `appNavigatorKey`, которым он
/// владеет: до него дотягиваются и бургер, и клиент API при истёкшей сессии.
final AppRouterDelegate appRouter = AppRouterDelegate();
