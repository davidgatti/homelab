{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix 
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "24.05";
  networking.hostName = "PiHole";

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
    docker
  ];

  # Enable Docker with default configuration only
  virtualisation.docker.enable = true;

  systemd.services.install-pihole = {
    description = "Install and run Pi-hole in Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";

      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop pihole"
        "-${pkgs.docker}/bin/docker rm pihole"
      ];

      ExecStart = "${pkgs.docker}/bin/docker run -d --name pihole "
        + "--net=host "
        + "-e TZ=\"Europe/Rome\" "
        + "-e WEBPASSWORD=\"password\" "
        + "-e DNSMASQ_LISTENING=\"all\" "
        + "-e DNSSEC=\"true\" "
        + "-e DNS_FQDN_REQUIRED=\"true\" "
        + "-e DNS_BOGUS_PRIV=\"true\" "
        + "-v /etc/pihole:/etc/pihole "
        + "-v /etc/dnsmasq.d:/etc/dnsmasq.d "
        + "pihole/pihole";
    };
  };

}