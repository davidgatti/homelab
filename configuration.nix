```
{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
  };
in
{
  imports =
    [
      ./hardware-configuration.nix
      "${home-manager}/nixos"  # Home Manager module for NixOS
    ];

  # Setting system state version for stability
  system.stateVersion = "24.05";

  # Required for booting with GRUB on compatible hardware
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda1" ]; # Replace with your actual boot disk, e.g., /dev/sda
  };

  # SSH and networking configurations
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = true;
  };
  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 22 8081 53 67 80 8123 ]; # Open ports for SSH, VS Code Server, Pi-hole, and Home Assistant

  # User settings
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    password = "nixos";
  };

  # Environment and system packages
  environment.systemPackages = with pkgs; [
    htop
    code-server
    docker
  ];

  # Code Server configuration
  services.code-server = {
    enable = true;
    user = "nixos";
    port = 8081;
    host = "0.0.0.0";
  };

  # Docker setup for Pi-hole and Home Assistant with conflict handling
  systemd.services.install-pihole = {
    description = "Install and run Pi-hole in Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = ''
        ${pkgs.docker}/bin/docker stop pihole || true
        ${pkgs.docker}/bin/docker rm pihole || true
      '';
      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d --name pihole \
          --net=host \
          -e TZ="Europe/Rome" \
          -e WEBPASSWORD="your_password_here" \
          -v /etc/pihole:/etc/pihole \
          -v /etc/dnsmasq.d:/etc/dnsmasq.d \
          --restart=unless-stopped \
          pihole/pihole
      '';
      RemainAfterExit = true;
    };
  };

  systemd.services.install-homeassistant = {
    description = "Install and run Home Assistant in Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = ''
        ${pkgs.docker}/bin/docker stop homeassistant || true
        ${pkgs.docker}/bin/docker rm homeassistant || true
      '';
      ExecStart = ''
        ${pkgs.docker}/bin/docker run -d --name homeassistant \
          --net=host \
          -e TZ="Europe/Rome" \
          -v /etc/homeassistant:/config \
          --restart=unless-stopped \
          homeassistant/home-assistant:stable
      '';
      RemainAfterExit = true;
    };
  };

  # Home Manager configuration for user-level management (replace accordingly)
  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.05";
    home.packages = [ pkgs.htop pkgs.fortune ];
    programs.bash.enable = true;
  };
}
```
