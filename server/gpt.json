  # Docker-based service for open-webui
  systemd.services.open-webui = {
    description = "Open WebUI Service";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop open-webui || true"
        "-${pkgs.docker}/bin/docker rm open-webui || true"
      ];
      ExecStart = "${pkgs.docker}/bin/docker run -d "
            + "--name open-webui "
            + "-p 3000:8080 "
            + "--restart always "
            + "-e OLLAMA_BASE_URL=http://127.0.0.1:11434 "
            + "-v open-webui:/app/backend/data "
            + "ghcr.io/open-webui/open-webui:ollama";
    };
  };
