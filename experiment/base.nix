{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix 
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    grub.enable = false;  # Disable GRUB to prevent conflicts
  };

  system.stateVersion = "24.05";  # Ensure stateVersion is set

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

  virtualisation.docker.enable = true;

  services.code-server = {
    enable = true;
    user = "nixos";
    port = 8080;
    host = "0.0.0.0";
  };
}
