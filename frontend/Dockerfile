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

# Настройки сборки. Значения по умолчанию заданы в lib/helper/app_config.dart
# и api_config.dart, здесь их можно перебить; пустая строка = «оставить дефолт».
# API_ORIGIN вебу задавать не нужно — сборка берёт origin страницы, поэтому один
# образ работает и на localhost:8080, и на боевом домене, и по HTTPS.
ARG API_ORIGIN=""
ARG MAP_TILE_URL=""
ARG OSM_USER_AGENT=""
RUN flutter build web --release \
      --dart-define=API_ORIGIN=${API_ORIGIN} \
      $( [ -n "${MAP_TILE_URL}" ] && echo --dart-define=MAP_TILE_URL=${MAP_TILE_URL} ) \
      $( [ -n "${OSM_USER_AGENT}" ] && echo --dart-define=OSM_USER_AGENT=${OSM_USER_AGENT} )


FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Конфиг не копируем, а монтируем из infra/nginx.conf — правка проксирования
# не требует пересборки образа.
EXPOSE 80
