---
tags: [integrations, sentry, механик, apk]
date: 2026-09-18
---

# Крэш-репорты APK уходят в Sentry только со сборки CI

Падения приложения на телефоне видны в Sentry: организация `rr-oe`,
проект `els-app` (платформа Flutter). Каждое событие несёт `release =
els@<versionName>+<versionCode>`, поэтому по Issues видно, в какой сборке
упало.

`frontend/lib/helper/crash_reporting.dart` (`CrashReporting.run()`)
включает `SentryFlutter.init` только при `--dart-define=SENTRY_DSN`. DSN
лежит в секретах репозитория и подставляется в джобе `build apk`
(`apk info` печатает «Sentry: включён»). Локальная сборка и веб без DSN —
Sentry молчит, шума с dev-точек нет. Пойманные ошибки шлются вручную
через `CrashReporting.report()`. Трассировка производительности выключена.

## Что важно не забыть

- Бэкенд Sentry не подключён — сознательно отдельная работа
  (`sentry-sdk` в FastAPI, DSN в `.env` прода).
- «Zone mismatch» в консоли dev-точки — только веб, в APK зон нет.
- Пока падений в проде не было: первое событие с `release els@1.0.5+6`
  появится само; смотреть Issues, когда механики жалуются на «вылетело».
- Проверить руками: `lib/dev/crash_preview.dart` — три кнопки, события
  приходят с `release els@0.0.0-dev+1`.

Связано: [[APK механика собирает CI, а на сайт выкладывает publish-apk с ноутбука]].
