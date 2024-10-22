# config.nix
{ config, lib, pkgs, piHoleEnable ? false, homeAssistantEnable ? false, ... }:

{
  imports = [
    ./base.nix
    ./modules/pihole.nix
    ./modules/homeassistant.nix
  ];

  # Use the passed-in parameters to set the options
  services.pihole.enable = piHoleEnable;
  services.homeassistant.enable = homeAssistantEnable;
}
