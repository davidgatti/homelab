# modules/homeassistant.nix
{ config, lib, pkgs, ... }:

with lib;

{
  options.services.homeassistant.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Home Assistant service.";
  };

  config = mkIf config.services.homeassistant.enable {
    systemd.services.homeassistant = {
      description = "Install and run Home Assistant in Docker";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        After = [ "docker.service" ];
        RemainAfterExit = true;
            
        ExecStartPre = [
          "-${pkgs.docker}/bin/docker stop homeassistant"
          "-${pkgs.docker}/bin/docker rm homeassistant"
        ];

        ExecStart = "${pkgs.docker}/bin/docker run -d --name homeassistant "
                  + "--net=host "
                  + "-e TZ=\"Europe/Rome\" "
                  + "-v /etc/homeassistant:/config "
                  + "homeassistant/home-assistant:latest";
      };
    };
  };
}
