services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: always
    environment:
      - SIGNUPS_ALLOWED=false
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/vaultwarden:/data
    ports:
      - "8072:88"