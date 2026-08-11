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

# Адрес API. По умолчанию относительный путь: веб ходит на тот же origin,
# что и сам отдаётся, поэтому CORS в браузере не участвует вовсе.
ARG API_BASE_URL=/api/v1
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}


FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Конфиг не копируем, а монтируем из infra/nginx.conf — правка проксирования
# не требует пересборки образа.
EXPOSE 80
