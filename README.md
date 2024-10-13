# Manual Instalaltion

```
# Partition, format, mount, generate configuration, edit configuration.nix, and install NixOS in one go
(
# Partition the disk
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
) | fdisk /dev/sda            # Run fdisk on /dev/sda

# Format the partitions
mkfs.fat -F 32 /dev/sda1        # Force format EFI partition as FAT32
mkfs.ext4 -F /dev/sda2          # Force format root partition as ext4

# Mount the partitions
mount /dev/sda2 /mnt            # Mount root partition
mkdir -p /mnt/boot              # Create boot directory
mount /dev/sda1 /mnt/boot       # Mount EFI partition

# Generate NixOS configuration
nixos-generate-config --root /mnt

# Use sed to insert SSH settings, including password authentication, and firewall settings before the last }
sed -i '/^}$/i \
  services.openssh = {\n\
    enable = true;\n\
    permitRootLogin = "yes";\n\
    passwordAuthentication = true;\n\
  };\n\
  networking.firewall.allowedTCPPorts = [ 22 ];' /mnt/etc/nixos/configuration.nix

# Install NixOS
nixos-install

# Unmount and reboot
umount -R /mnt
reboot
```
