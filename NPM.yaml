services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      # Public HTTP Port
      - '90:90'
      # Public HTTPS Port
      - '440:440'
      # NPM Admin Web Interface
      - '70:70'
    dns:
      - 8.8.8.8
      - 1.1.1.1
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/npm/data:/data
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/npm/letsencrypt:/etc/letsencrypt