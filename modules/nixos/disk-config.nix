# NixOS Disk Configuration (Disko)
#
# GPT partition layout with systemd-boot EFI and ext4 root filesystem.
# Configures disk partitioning scheme for automated NixOS installations.
#
# PARTITIONS:
#   - ESP (EFI System Partition): 100MB vfat, mounted at /boot
#   - Root: Remaining space, ext4, mounted at /
#
# NOTE: %DISK% placeholder replaced during installation (e.g., /dev/sda, /dev/nvme0n1)
#
# REFERENCE: https://github.com/nix-community/disko/tree/master/example

{ lib, ... }:
{
  disko.devices = lib.mkDefault {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "100M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
