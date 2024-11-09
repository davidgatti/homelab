{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {};
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
                  + "-v /run/dbus:/run/dbus:ro "
                  + "-v /mnt/music:/media/music:rw "
                  + "homeassistant/home-assistant:latest";
    };
  };

  systemd.services.jellyfin = {
    description = "Jellyfin Media Server";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";

      # Pre-start commands to ensure volumes are created
      ExecStartPre = [
        # Ensure volume for config is created
        "${pkgs.docker}/bin/docker volume create jellyfin-config"

        # Ensure volume for cache is created
        "${pkgs.docker}/bin/docker volume create jellyfin-cache"

        # Stop and remove existing container if it exists
        "-${pkgs.docker}/bin/docker stop jellyfin || true"
        "-${pkgs.docker}/bin/docker rm jellyfin || true"
      ];

      # Start the Jellyfin container with volume mounts
      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d --name jellyfin \
          -p 8096:8096 \
          --restart always \
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
    options = [ "username=media" "password=PASSWORD" "rw" ];
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
