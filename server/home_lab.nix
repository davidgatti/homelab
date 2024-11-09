# 
# sudo nixos-rebuild switch -I nixos-config=$HOME/home_lab.nix
#

{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> { };
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  nixpkgs.config.allowUnfree = true;

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
    extraGroups = [ "wheel" "docker" "video" "render" ];
    password = "nixos";
  };

  environment.systemPackages = with pkgs; [
    home-manager
    code-server
    docker
    nixpkgs-fmt
    cifs-utils
    rocm-opencl-icd
    rocmPackages.rocminfo
  ];

  services.code-server = {
    enable = true;
    user = "nixos";
    port = 8080;
    host = "0.0.0.0";
  };

  services.ollama = {
    package = unstable.ollama;
    enable = true;
    acceleration = "rocm"; # or "cuda"
  };

  # Enable Docker with default configuration only
  virtualisation.docker.enable = true;

  # Enable Bluetooth hardware support
  hardware.bluetooth.enable = true;

  systemd.services.docker-macvlan = {
    description = "Docker macvlan network setup";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.docker}/bin/docker network create -d macvlan \
          --subnet=192.168.2.0/24 \
          --gateway=192.168.2.1 \
          -o parent=enp1s0 \
          home_bridge
      '';
      ExecStop = "${pkgs.docker}/bin/docker network rm home_bridge";
    };
  };

  systemd.services.install-homeassistant = {
    description = "Install and run Home Assistant in Docker";
    after = [ "docker.service" "docker-macvlan.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop homeassistant || true"
        "-${pkgs.docker}/bin/docker rm homeassistant || true"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d --name homeassistant \
          --network=home_bridge \
          --ip=192.168.2.11 \
          --hostname HomeAssistant \
          --mac-address B8:27:EB:12:34:56 \
          -e TZ="Europe/Rome" \
          -v /etc/homeassistant:/config \
          -v /run/dbus:/run/dbus:ro \
          -v /mnt/music:/media/music:rw \
          homeassistant/home-assistant:latest
      '';
    };
  };

  systemd.services.jellyfin = {
    description = "Jellyfin Media Server";
    after = [ "docker.service" "docker-macvlan.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStartPre = [
        "${pkgs.docker}/bin/docker volume create jellyfin-config"
        "${pkgs.docker}/bin/docker volume create jellyfin-cache"
        "-${pkgs.docker}/bin/docker stop jellyfin || true"
        "-${pkgs.docker}/bin/docker rm jellyfin || true"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d --name jellyfin \
          --network=home_bridge \
          --ip=192.168.2.12 \
          --hostname Jellyfin \
          --mac-address B8:27:EB:12:34:57 \
          -e TZ="Europe/Rome" \
          -v /mnt/media:/media:ro \
          -v jellyfin-config:/config \
          -v jellyfin-cache:/cache \
          jellyfin/jellyfin:latest
      '';
    };
  };

  fileSystems."/mnt/media" = {
    device = "//192.168.2.2/media";
    fsType = "cifs";
    options = [ "username=media" "password=sdsd" "rw" ];
  };

  fileSystems."/mnt/dropbox" = {
    device = "//192.168.2.2/dropbox";
    fsType = "cifs";
    options = [
      "guest"
      "uid=1000"
      "gid=100"
      "file_mode=0644"
      "dir_mode=0755"
      "rw"
      "vers=3.0"
    ];
  };

}
