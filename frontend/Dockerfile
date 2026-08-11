# Веб-сборка фронта. Собирается внутри контейнера, поэтому Flutter SDK
# на машине не нужен — он нужен только для мобильных сборок и hot reload.
#
# Сборка идёт из корня репозитория: make up

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Сначала только манифесты — слой с зависимостями переиспользуется,
# пока pubspec не менялся.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Адрес бэкенда. Пустое значение — правильное значение по умолчанию: веб-сборка
# сама берёт origin страницы (см. lib/helper/api_config.dart), поэтому один образ
# работает и на localhost:8080, и на боевом домене, и по HTTPS.
# Задавать нужно только если API живёт на другом хосте, чем сам фронт.
ARG API_ORIGIN=""
RUN flutter build web --release --dart-define=API_ORIGIN=${API_ORIGIN}


FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Конфиг не копируем, а монтируем из infra/nginx.conf — правка проксирования
# не требует пересборки образа.
EXPOSE 80
