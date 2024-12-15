# NixOS Setup Guide

## OS Installation

### Boot

1. **Insert the NixOS USB into the PC**:
   - Make sure the USB is inserted properly before booting.

1. **Boot from USB**:
   - Go to the BIOS and ensure the PC is set to boot from the USB drive.

1. **Boot into NixOS**:
   - Once prompted, select the option to boot into NixOS from the USB.

1. **Set a temporary password**:
   - Once NixOS is running, set a password to enable remote access via SSH. Run the following command in the terminal:
     ```bash
     passwd
     ```
   - Follow the prompts to set a password. This password will be used later for SSH access.

1. **Find the PC’s IP address**:
   - Run the following command to find the PC’s IP address:
     ```bash
     ip addr show
     ```
   - Note down the IP address, which you’ll use to connect via SSH.

1. **Connect remotely via SSH**:
   - From another computer on the same network, connect to the PC using the following command (replace `IP` with the actual IP address of the PC):
     ```bash
     ssh nixos@IP
     ```
   - Use the password you just set when prompted.

### Install

Copy and paste the following in the terminal to start the installation process.

```bash
sudo bash -c '
# Detect the main drive (largest, non-removable drive)
MAIN_DRIVE=$(lsblk -nd -o NAME,SIZE,TYPE | grep -Ev "loop|rom" | sort -k2 -h | tail -1 | awk "{print \"/dev/\" \$1}")

# Determine if the main drive is NVMe or not
if [[ "$MAIN_DRIVE" == *nvme* ]]; then
  PART1="${MAIN_DRIVE}p1"
  PART2="${MAIN_DRIVE}p2"
else
  PART1="${MAIN_DRIVE}1"
  PART2="${MAIN_DRIVE}2"
fi

(
echo g                        # Create a new GPT partition table
echo n                        # New partition (EFI)
echo 1                        # Partition number 1
echo                          # Default - start at beginning of disk
echo +512M                    # 512 MB EFI partition
echo t                        # Change type
echo 1                        # Set type to EFI System
echo n                        # New partition (Root)
echo 2                        # Partition number 2
echo                          # Default - start immediately after previous partition
echo                          # Use remaining space
echo w                        # Write changes
) | fdisk "$MAIN_DRIVE"       # Run fdisk on the detected main drive

# Reload partition table to recognize new partitions
partprobe "$MAIN_DRIVE"

# Format the partitions
mkfs.fat -F 32 "$PART1"       # Force format EFI partition as FAT32
mkfs.ext4 -F "$PART2"         # Force format root partition as ext4

# Mount the partitions
mount "$PART2" /mnt           # Mount root partition
mkdir -p /mnt/boot            # Create boot directory
mount "$PART1" /mnt/boot      # Mount EFI partition

# Set secure permissions on /boot
chmod 700 /mnt/boot           # Restrict access to /boot

# Generate NixOS configuration
nixos-generate-config --root /mnt

# Insert SSH and firewall settings into configuration.nix
sed -i "/^}$/i \
  services.openssh = {\n\
    enable = true;\n\
    settings.PermitRootLogin = \"no\";\n\
    settings.PasswordAuthentication = true;\n\
  };\n\
  networking.firewall.allowedTCPPorts = [ 22 ];\n\
  users.users.nixos = {\n\
    isNormalUser = true;\n\
    extraGroups = [ \"wheel\" ];\n\
    password = \"password\"; # Set a default password (replace as needed)\n\
  };" /mnt/etc/nixos/configuration.nix

# Install NixOS
nixos-install

# Set the root password non-interactively
echo "root:root" | chroot /mnt chpasswd

# Unmount and reboot
umount -R /mnt
reboot
'
```

## OS Configuration

1. **Remove `known_hosts` (if necessary)**:
1. **Reconnect via SSH**:
   - Connect to the newly installed NixOS system:
     ```bash
     ssh nixos@IP
     ```
   - Use the password you set during the installation process.

Once connected via SSH, proceed with the NixOS configuration. Copy and paste the following command to start the configuration process:

### DNS Setup

```bash
sudo bash -c ': > /etc/nixos/configuration.nix && \
curl -L https://raw.githubusercontent.com/davidgatti/nixos_setup/main/server/dns.nix -o /etc/nixos/configuration.nix && \
nixos-rebuild switch && \
cat ~/.config/code-server/config.yaml'
```

### HomeLab Setup

```bash
sudo bash -c ': > /etc/nixos/configuration.nix && \
curl -L https://raw.githubusercontent.com/davidgatti/nixos_setup/main/server/home_lab.nix -o /etc/nixos/configuration.nix && \
nixos-rebuild switch && \
cat ~/.config/code-server/config.yaml'
```

## User Configuration

```bash
curl -L https://raw.githubusercontent.com/davidgatti/nixos_setup/main/user/home.nix -o ~/.config/home-manager/home.nix && \
home-manager switch
```

# 🧐 F.A.Q

### **System Configuration and Updates**
- **`sudo nixos-rebuild switch -I nixos-config=./configuration.nix`**  
  This command rebuilds the system configuration from a specified `configuration.nix` file and immediately switches the system to use the new configuration. Use this after modifying the `configuration.nix` file to apply updates, such as installing packages, enabling services, or changing system settings.

- **`sudo nixos-rebuild switch --upgrade`**  
  Similar to the above command but also updates all system packages and channels to their latest versions before applying the new configuration. Use this regularly to keep your system updated.

- **`nix-channel --update`**  
  Updates all configured NixOS and Nix channels to fetch the latest package definitions. Run this command before upgrading your system to ensure you’re using the latest package versions.

### **Maintenance and Cleanup**
- **`nix-collect-garbage -d`**  
  Removes unused packages and old system generations from the nix store to free up disk space. Useful for cleaning up leftover files after multiple system rebuilds.

- **`nix-store --optimise`**  
  Deduplicates files in the nix store to reduce its size and optimize space usage. Use this periodically to clean up redundant files.

- **`nix-store --gc`**  
  Performs garbage collection on the nix store to remove all paths not referenced by any active system or user profile. This is less aggressive than `nix-collect-garbage`.

- **`nix-store --verify --repair`**  
  Verifies the integrity of files in the nix store and repairs any corrupted paths. Use this if you suspect issues with your nix store or after unexpected interruptions like a power outage.

- **`sudo journalctl --vacuum-time=1w`**  
  Deletes old system logs (e.g., logs older than one week) to free up disk space. Adjust the time (`1w`, `1m`, etc.) as needed.

- **`sudo du -sh /nix`**  
  Checks the size of the nix store to monitor its growth and identify when cleanup might be needed.

### **Diagnostics and Debugging**
- **`nix-store --verify`**  
  Checks the integrity of the nix store without repairing it. Use this to identify any issues with stored files.

- **`journalctl -xe`**  
  Displays detailed system logs with a focus on recent errors. Use this to troubleshoot issues with services or the system.

- **`systemctl status <service>`**  
  Checks the status of a specific service to determine if it is running, stopped, or encountering issues.

- **`nix why-depends <package> <dependency>`**  
  Explains why a package depends on a specific dependency. This is useful for debugging dependency-related issues.

### **Package Management**
- **`nix-env --upgrade`**  
  Upgrades all user-installed packages to their latest versions. This does not affect system-wide packages.

- **`nix-env -q`**  
  Lists all packages installed in the user environment.

- **`nix-env -e <package>`**  
  Removes a package from the user environment.

- **`nix-shell`**  
  Launches an isolated shell environment with specific dependencies. This is useful for temporary setups or development work without permanently installing packages.

### Suggested Routine for NixOS Maintenance
1. Regularly update channels and rebuild your system:
   ```bash
   nix-channel --update
   sudo nixos-rebuild switch --upgrade
   ```

2. Clean up unused data:
   ```bash
   nix-collect-garbage -d
   nix-store --optimise
   ```

3. Periodically verify the system:
   ```bash
   nix-store --verify
   journalctl -xe
   ```

4. Check disk usage and manage logs:
   ```bash
   sudo du -sh /nix
   sudo journalctl --vacuum-time=1w
   ```

