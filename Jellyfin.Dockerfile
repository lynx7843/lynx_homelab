version: '3.5'
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000  # Usually 1000 for the first user you created
      - PGID=100  # Usually 100 for the users group
      - TZ=Asia/Colombo
    volumes:
      # This puts the database on your fast SSD HotStorage
      - /srv/dev-disk-by-uuid-YOUR-SSD-UUID/Appdata/jellyfin:/config
      # This points to your ColdStorage Movies folder
      - /srv/dev-disk-by-uuid-YOUR-HDD-UUID/ColdStorage/Movies:/data/movies
      # This points to your HotStorage Tv shows folder
      - /srv/dev-disk-by-uuid-YOUR-SSD-UUID/HotStorage/Tv shows:/data/movies
    ports:
      - 8090:8090
    restart: unless-stopped