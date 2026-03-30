#! /usr/bin/env sh

# Установите рабочий каталог для alembic и выполнения миграций
cd /app

# Run migrations
alembic upgrade head
