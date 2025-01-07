#
# sudo nixos-rebuild switch -I nixos-config=$HOME/home_lab.nix
#

{ config, lib, pkgs, ... }: 

{
    imports = [ /etc/nixos/hardware-configuration.nix ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    system.stateVersion = "24.05";
    networking.hostName = "HomeLab";

    # Disable firewall, since it causes problems
    networking.firewall.enable = false;
    
    # Enable Docker with default configuration only
    virtualisation.docker.enable = true;

    # Enable Bluetooth hardware support
    hardware.bluetooth.enable = true;

    services.openssh = {
        enable = true;
        settings.PermitRootLogin = "no";
        settings.PasswordAuthentication = true;
    };

    users.users.nixos = {
        isNormalUser = true;
        password = "nixos";
        extraGroups =[ "wheel" "docker" "video" "render" ];
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZeLeV6OguRFHf6SArcMMJMVFABQu7n72YcdOe0NX6h"
        ];
    };

    environment.systemPackages = with pkgs;[
        home-manager
        docker
        code-server
        nixpkgs-fmt
    ];

    services.code-server = {
        enable = true;
        user = "nixos";
        port = 8080;
        host = "0.0.0.0";
    };

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
                --hostname homeassistant \
                --mac-address B8:27:EB:12:34:56 \
                -e TZ="Europe/Rome" \
                -v /etc/homeassistant:/config \
                -v /run/dbus:/run/dbus:ro \
                -v /mnt/music:/media/music:rw \
                --device=/dev/bus/usb \
                --privileged \
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
                --hostname jellyfin \
                --mac-address B8:27:EB:12:34:57 \
                -e TZ="Europe/Rome" \
                -v /mnt/media:/media:ro \
                -v jellyfin-config:/config \
                -v jellyfin-cache:/cache \
                jellyfin/jellyfin:latest
            '';
        };
    };

    systemd.services.node-red = {
        description = "Node-RED Service";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create nodered-data"
                "-${pkgs.docker}/bin/docker stop node-red || true"
                "-${pkgs.docker}/bin/docker rm node-red || true"
            ];
            ExecStart = ''
                ${pkgs.docker}/bin/docker run -d --name node-red \
                --network=home_bridge \
                --ip=192.168.2.16 \
                --hostname node-red \
                --mac-address B8:27:EB:12:34:58 \
                -e TZ="Europe/Rome" \
                -e PORT=80 \
                -v nodered-data:/data:rw \
                nodered/node-red:latest
            '';
        };
    };

    systemd.services.n8n = {
        description = "n8n Service";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create n8n-data"
                "-${pkgs.docker}/bin/docker stop n8n || true"
                "-${pkgs.docker}/bin/docker rm n8n || true"
            ];
            ExecStart = ''
                ${pkgs.docker}/bin/docker run -d --name n8n \
                --network=home_bridge \
                --ip=192.168.2.17 \
                --hostname n8n \
                --mac-address B8:27:EB:12:34:59 \
                -e N8N_SECURE_COOKIE=false \
                -e GENERIC_TIMEZONE=Europe/Rome \
                -e N8N_PORT=80 \
                -v n8n-data:/home/node/.n8n:rw \
                n8nio/n8n:latest
            '';
        };
    };

    systemd.services.qdrant = {
        description = "Qdrant Vector Database Service";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create qdrant-data"
                "-${pkgs.docker}/bin/docker stop qdrant || true"
                "-${pkgs.docker}/bin/docker rm qdrant || true"
            ];
            ExecStart = ''
                ${pkgs.docker}/bin/docker run -d --name qdrant \
                --network=home_bridge \
                --ip=192.168.2.18 \
                --hostname qdrant \
                --mac-address B8:27:EB:12:34:60 \
                -e TZ="Europe/Rome" \
                -v qdrant-data:/qdrant/storage:rw \
                qdrant/qdrant
            '';
        };
    };

    fileSystems."/mnt/media" = {
        device = "//192.168.2.2/media";
        fsType = "cifs";
        options =[ "username=media""password=*vL9wax8!HeBM3BoJ9*z@RR4N7oP2NKCPb7ybQhVhnavakXrJs""rw" ];
    };

    fileSystems."/mnt/dropbox" = {
        device = "//192.168.2.2/dropbox";
        fsType = "cifs";
        options =[
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
