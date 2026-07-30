# create and use your own db name, user name and passwords
services:
  dawarich:
    image: freikin/dawarich:latest
    container_name: dawarich
    command: sh -c "bin/rails db:prepare && bin/rails server -b 0.0.0.0 -p 3000"
    restart: unless-stopped
    ports:
      - 8081:3000
    dns:
      - 8.8.8.8
      - 1.1.1.1
    environment:
      - TIME_ZONE=Asia/Colombo
      - DATABASE_HOST=dawarich-db
      - DATABASE_USERNAME=
      - DATABASE_PASSWORD=
      - DATABASE_NAME=
      - REDIS_URL=redis://dawarich-redis:6379/0
      - APPLICATION_HOSTS=
      - BACKGROUND_PROCESSING=true
    depends_on:
      dawarich-db:
        condition: service_healthy
      dawarich-redis:
        condition: service_started

  dawarich-sidekiq:
    image: freikin/dawarich:latest
    container_name: dawarich-sidekiq
    command: sidekiq
    restart: unless-stopped
    environment:
      - TIME_ZONE=Asia/Colombo
      - DATABASE_HOST=
      - DATABASE_USERNAME=
      - DATABASE_PASSWORD=
      - DATABASE_NAME=
      - REDIS_URL=redis://dawarich-redis:6379/0
    depends_on:
      dawarich-db:
        condition: service_healthy
      dawarich-redis:
        condition: service_started

  dawarich-db:
    image: postgis/postgis:15-3.4-alpine
    container_name: 
    restart: unless-stopped
    environment:
      - POSTGRES_USER=
      - POSTGRES_PASSWORD=
      - POSTGRES_DB=
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/dawarich/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dawarich -d dawarich_production"]
      interval: 5s
      timeout: 5s
      retries: 5

  dawarich-redis:
    image: redis:7-alpine
    container_name: dawarich-redis
    restart: unless-stopped
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/dawarich/redis:/data