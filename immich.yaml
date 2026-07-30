services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    ports:
      - 80823:2000
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/ImmichLibrary:/usr/src/app/upload
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Pictures:/usr/src/app/external:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=Asia/Colombo
      - DB_HOSTNAME=
      - DB_USERNAME=postgres
      - DB_PASSWORD=
      - DB_DATABASE_NAME=
      - REDIS_HOSTNAME=immich_redis
    depends_on:
      - immich_postgres
      - immich_redis
    restart: unless-stopped

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/immich/model-cache:/cache
    environment:
      - TZ=Asia/Colombo
    restart: unless-stopped

  immich_redis:
    container_name: immich_redis
    image: redis:6.2-alpine
    restart: unless-stopped

  immich_postgres:
    container_name: immich_postgres
    image: pgvector/pgvector:pg14
    environment:
      POSTGRES_PASSWORD:
      POSTGRES_USER:
      POSTGRES_DB:
      POSTGRES_INITDB_ARGS: '--data-checksums'
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/immich/postgres:/var/lib/postgresql/data
    restart: unless-stopped