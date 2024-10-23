{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix 
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
    git
    gh
    nixpkgs-fmt
  ];

  # Enable Docker with default configuration only
  virtualisation.docker.enable = true;

  services.code-server = {
    enable = true;
    user = "nixos";
    port = 8080;
    host = "0.0.0.0";
  };

  systemd.services.install-homeassistant = {
    description = "Install and run Home Assistant in Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";

      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop homeassistant || true"
        "-${pkgs.docker}/bin/docker rm homeassistant || true"
      ];

      ExecStart = "${pkgs.docker}/bin/docker run -d --name homeassistant "
                + "-p 8123:8123 "
                + "--net=host "
                + "-e TZ=\"Europe/Rome\" "
                + "-v /etc/homeassistant:/config "
                + "homeassistant/home-assistant:latest";
      
    };
  };
}