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

    networking.firewall.enable = false;

    # Enable Docker with additional options
    virtualisation.docker = {
        enable = true;
        extraOptions = "--default-ulimit nofile=65535:65535";
    };

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

    # Add global systemd limit for file descriptors
    systemd.extraConfig = ''
      DefaultLimitNOFILE=65535
    '';

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

    systemd.services.homeassistant = {
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
                --ulimit nofile=65535:65535 \
                homeassistant/home-assistant:latest
            '';
            LimitNOFILE = 65535;
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
                --no-healthcheck \
                jellyfin/jellyfin:latest
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

    systemd.services.openttd = {
        description = "OpenTTD Game Server";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create openttd-data"
                "-${pkgs.docker}/bin/docker stop openttd || true"
                "-${pkgs.docker}/bin/docker rm openttd || true"
            ];
            ExecStart = ''
                ${pkgs.docker}/bin/docker run -d --name openttd \
                --network=home_bridge \
                --ip=192.168.2.19 \
                --hostname openttd \
                --mac-address B8:27:EB:12:34:61 \
                -e TZ="Europe/Rome" \
                -v /home/your_username/Documents/open_ttd/main.cfg:/openttd/data/openttd.cfg:ro \
                -p 3979:3979 \
                -p 3978:3978/udp \
                ghcr.io/ropenttd/openttd:latest
            '';
        };
    };

    systemd.services.openra-red-alert = {
        description = "OpenRA Red Alert Game Server";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create openra-red-alert-data"
                "-${pkgs.docker}/bin/docker stop openra-red-alert || true"
                "-${pkgs.docker}/bin/docker rm openra-red-alert || true"
            ];
            ExecStart = ''
                ${pkgs.docker}/bin/docker run -d --name openra-red-alert \
                --network=home_bridge \
                --ip=192.168.2.20 \
                --hostname openra-red-alert \
                --mac-address B8:27:EB:12:34:65 \
                -e Name="Red Alert Server" \
                -e Mod="ra" \
                -e AdvertiseOnline=True \
                -e Password="redalertpass" \
                -v openra-red-alert-data:/home/openra/.openra:rw \
                -p 1234:1234 \
                -p 1234:1234/udp \
                ghcr.io/dkruyt/openra:latest
            '';
        };
    };

    systemd.services.postgres = {
        description = "PostgreSQL Database Server";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create postgres-data"
                "-${pkgs.docker}/bin/docker stop postgres || true"
                "-${pkgs.docker}/bin/docker rm postgres || true"
            ];
            ExecStart = ''
            ${pkgs.docker}/bin/docker run -d --name postgres \
            --network=home_bridge \
            --ip=192.168.2.21 \
            --hostname postgres \
            --mac-address B8:27:EB:12:34:66 \
            -e POSTGRES_USER=admin \
            -e POSTGRES_PASSWORD=password \
            -e POSTGRES_DB=default \
            -v postgres-data:/var/lib/postgresql/data \
            -p 5432:5432 \
            postgres:latest
            '';
        };
    };

    systemd.services.redis = {
        description = "Redis Server";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create redis-data"
                "-${pkgs.docker}/bin/docker stop redis || true"
                "-${pkgs.docker}/bin/docker rm redis || true"
            ];
            ExecStart = ''
            ${pkgs.docker}/bin/docker run -d --name redis \
            --network=home_bridge \
            --ip=192.168.2.22 \
            --hostname redis \
            --mac-address B8:27:EB:12:34:67 \
            -v redis-data:/data \
            -p 6379:6379 \
            redis:latest --appendonly yes
            '';
        };
    };

    systemd.services.docmost = {
        description = "Docmost Server";
        after = [ "docker.service" "docker-macvlan.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStartPre = [
                "${pkgs.docker}/bin/docker volume create docmost-data"
                "-${pkgs.docker}/bin/docker stop docmost || true"
                "-${pkgs.docker}/bin/docker rm docmost || true"
            ];
            ExecStart = ''
            ${pkgs.docker}/bin/docker run -d --name docmost \
            --network=home_bridge \
            --ip=192.168.2.23 \
            --hostname docmost \
            --mac-address B8:27:EB:12:34:68 \
            -e APP_URL="http://192.168.2.23" \
            -e APP_SECRET="a3f2e1d6c9b82e4740d64f1a8e2cbd8c" \
            -e DATABASE_URL="postgresql://admin:password@192.168.2.21:5432/docmost?schema=public" \
            -e REDIS_URL="redis://192.168.2.22:6379" \
            -e PORT=80 \
            -v docmost-data:/app/data/storage \
            docmost/docmost:latest
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
