services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open_webui
    restart: unless-stopped
    ports:
      - 8183:8180
    dns:
      - 8.8.8.8
      - 1.1.1.1
    volumes:
      - /srv/dev-disk-by-uuid-YOUR UUID/HotStorage/Appdata/openwebui:/app/backend/data
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=Asia/Colombo
      - ENABLE_OLLAMA_API=False