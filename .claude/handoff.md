---
этап: 5 — APK механикам, часть вторая: подпись, раздача с сайта, экран
статус: в работе
дата: 2026-09-07
план: `~/.claude/plans/sorted-launching-wilkes.md` — этапы A…G, утверждён
---

# Передача: код этапов A и B написан и проверен, но **ничего не закоммичено**

## Сделано и проверено

- **Релизный APK собирается** — впервые: до этого CI собирал только debug.
  Локально дал 68 МБ; `aapt2 dump badging` — `ru.els23.app`, versionCode 1,
  minSdk 24, targetSdk 36. Ключа нет, поэтому `apksigner` показывает
  `CN=Android Debug`: откат на debug-подпись работает, сборка не падает.
- **Тулчейн на машине**: Temurin JDK 17 + Android SDK
  (`/opt/homebrew/share/android-commandlinetools`), лицензии приняты,
  `flutter doctor` даёт `[✓] Android toolchain`. Flutter стоял и раньше,
  `CLAUDE.md` утверждал обратное — исправлено.
- **Бэкенд раздачи готов**: `GET /app/release`, `POST /app/link`,
  `GET /app/download` в `endpoints/app_release.py`, манифест — в
  `core/app_release.py`. Байты отдаёт nginx через `X-Accel-Redirect`, правок
  nginx не потребовалось. `make lint` чист, `make test` — **995 пройдено**
  (14 новые), снимок OpenAPI обновлён.
- **Экран «Приложение»** — `frontend/lib/app_download/`, макет утверждён до
  написания логики. Вход из кабинета механика и по адресу `els23.ru/app`
  (разбор пути в `main.dart:98` — роутера в приложении нет). `dart analyze`
  по новым файлам чист.

## Не доделано

- **Keystore не создан, секретов в GitHub нет.** Без них обновления поверх
  раздаваемого APK ставиться не будут. Нужны `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- **APK не проверен на телефоне** (телефон найден, Android с Google) и на
  сервер не клали — `els23.ru/app` живьём не открывалась. Это этап C.
- **Push (этап D) не начат**: признака срочности в `Order` нет, только
  `fault_category_id`. **`make up` не гонялся** — на собранном стеке новый
  экран не проверен.
- **Миграция Flutter сама правила** `android/build.gradle` и
  `gradle.properties` (`tasks.register("clean")`, `android.newDsl=false`) —
  оставлено сознательно, в ревью показать.

## Следующий этап

**Цель.** Механик скачивает APK с els23.ru и ставит его на телефон.

**Готово, когда** APK с подписью релиза лежит на сервере, `els23.ru/app`
отдаёт его вошедшему и отказывает невошедшему, а приложение ставится на
живой телефон и открывается.

## Первые шаги

1. Ветка от `main`, коммит всей рабочей копии, PR — CI покажет, что
   релизная сборка зелёная и на раннере.
2. Keystore и четыре секрета (см. «Не доделано»), затем повторный прогон:
   в логе шага `apk info` не должно быть предупреждения про debug-ключ.
3. Скачать артефакт `els-apk`, положить в том `static_data` как
   `/app/static/app/els-1.0.0.apk` и `release.json` рядом (`versionName`,
   `versionCode`, `file`, `sha256`, `publishedAt`, `notes`), выкатить
   бэкенд, открыть `els23.ru/app`.

## Не трогать

- Прод, `els23.ru`, `make prod-deploy` — запускает человек.
- Офлайн не расширяем: объекты, справочники, дефектные акты — не в этот раз.
- Сжатие фото (`helper/image_picking.dart:47`, 1600 px / q70) — только
  проверить на телефоне; 21 сторож `if (kIsWeb)` — снимать после этапа C.
- `els_mobile/`, `soon_screen.dart`, заглушки `SizedBox.shrink()`; и
  `flutter pub get` без нужды — Flutter в CI и локально требуют разных
  версий `intl`, а разрешённые пакеты лежат в `.dart_tool/`.

## Уточнить перед стартом

- Домен оплачен до 20 октября, оформлен на Вову как на физлицо: кто платит и
  переносим ли администратора. Без продления 20 ноября уходит и HTTPS.
- Какие категории неисправности считать аварийными (нужно для этапа D).

## Ссылки

- `backend/src/core/app_release.py` — формат `release.json` для сервера.
- `frontend/android/app/build.gradle` — как подключается ключ релиза.
