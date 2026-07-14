services:
  glance:
    image: glanceapp/glance:latest
    container_name: glance
    restart: unless-stopped
    ports:
      - 8082:8070
    dns:
      - 8.8.8.8
      - 1.1.1.1
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/glance:/app/config
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro