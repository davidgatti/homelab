{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix 
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "24.05";
  networking.hostName = "HomeLab";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = true;
  };

  networking.firewall.enable = false;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "nixos" ];
    password = "nixos";
  };

  environment.systemPackages = with pkgs; [
    code-server
    docker
  ];

  # Enable Docker with default configuration only
  virtualisation.docker.enable = true;

  services.code-server = {
    enable = true;
    user = "nixos";
    port = 8080;
    host = "0.0.0.0";
  };

  systemd.services.install-pihole = {
    description = "Install and run Pi-hole in Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";

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
      RemainAfterExit = true;
    };
  };
}
