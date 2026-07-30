services:
  nextcloud:
    image: lscr.io/linuxserver/nextcloud:latest
    container_name: nextcloud
    environment:
      - PUID=1000
      - PGID=100
      - TZ=Asia/Colombo
    volumes:
      # SSD for snappy interface and caching
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/nextcloud:/config
      # HDD for massive file storage
      - /srv/dev-disk-by-uuid-YOUR UUID/ColdStorage/NextcloudData:/data
      # NEW: Your Fast Workspace (SSD)
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/NextcloudFast:/fast-workspace
    ports:
      - 8085:82
    restart: unless-stopped
    depends_on:
      - mariadb

  mariadb:
    image: mariadb:10.11
    container_name: 
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    environment:
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=
      - MYSQL_USER=
      - TZ=Asia/Colombo
    volumes:
      # SSD is MANDATORY for the database, or Nextcloud will freeze
      - /srv/dev-disk-by-YOUR UUID/HotStorage/Appdata/mariadb:/var/lib/mysql
    restart: unless-stopped