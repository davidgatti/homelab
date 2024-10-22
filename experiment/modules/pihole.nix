# modules/pihole.nix
{ config, lib, pkgs, ... }:

with lib;

{
  options.services.pihole.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Pi-hole service.";
  };

  config = mkIf config.services.pihole.enable {
    systemd.services.pihole = {
      description = "Install and run Pi-hole in Docker";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        After = [ "docker.service" ];
        RemainAfterExit = true;

        ExecStartPre = [
          "-${pkgs.docker}/bin/docker stop pihole"
          "-${pkgs.docker}/bin/docker rm pihole"
        ];

        ExecStart = "${pkgs.docker}/bin/docker run -d --name pihole "
                  + "--net=host "
                  + "-e TZ=\"Europe/Rome\" "
                  + "-e WEBPASSWORD=\"your_secure_password\" "
                  + "-e DNSMASQ_LISTENING=\"local\" "
                  + "-v /etc/pihole:/etc/pihole "
                  + "-v /etc/dnsmasq.d:/etc/dnsmasq.d "
                  + "pihole/pihole";
      };
    };
  };
}
