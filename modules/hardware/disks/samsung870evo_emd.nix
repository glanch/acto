{ pkgs, ... }: {
  environment.etc.crypttab = {
    enable = true;
    text = ''
      # sda3_crypt UUID=2644f599-e320-4c60-bc1a-bc0d4cba7d46 none luks
      crypted_emd UUID=ed778469-973d-4a42-8d97-05c3df73335b none luks noauto
    '';
  };
  # systemd.services."open-crypted_emd-luks" = {
  #   description = "Unlock crypted_emd LUKS volume";
  #   wantedBy = [ "multi-user.target" ];
  #   before = [
  #     "home-christopher-.qcow\\x2dstorage-emd-compressed.mount"
  #     "home-christopher-.qcow\\x2dstorage-emd-uncompressed.mount"
  #     "home-christopher-samsung870evo_emd.mount"
  #   ];

  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = [
  #       # Prompt for password in GUI (using systemd-ask-password GUI)
  #       "${pkgs.systemd}/bin/systemd-ask-password 'Enter passphrase for crypted_emd' | ${pkgs.cryptsetup}/bin/cryptsetup open /dev/disk/by-partlabel/disk-samsung870evo_emd-luks crypted_emd"
  #     ];
  #     RemainAfterExit = true;
  #   };
  # };
  disko.devices = {
    disk = {
      samsung870evo_emd = {
        type = "disk";
        device = "/dev/disk/by-uuid/ed778469-973d-4a42-8d97-05c3df73335b";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted_emd";
                initrdUnlock = false;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes =
                    let
                      generalMountOptions = [
                        #"allow_other" # for non-root access
                        #"_netdev" # this is a network fs
                        #"x-systemd.automount" # mount on demand
                        "nofail"
                        "noauto"
                      ];
                    in
                    {
                      "/root" = {
                        mountpoint = "/home/christopher/samsung870evo_emd";
                        mountOptions = generalMountOptions ++ [ "compress=zstd" "noatime" ];
                      };
                      "/.qcow_storage/uncompressed" = {
                        mountpoint = "/home/christopher/.qcow-storage/emd/uncompressed";
                        mountOptions = generalMountOptions ++ [ "noatime" "nodatacow" ];
                      };
                      "/.qcow_storage/compressed" = {
                        mountpoint = "/home/christopher/.qcow-storage/emd/compressed";
                        mountOptions = generalMountOptions ++ [ "compress=zstd" "noatime" "nodatacow" ];
                      };
                    };
                };
              };
            };
          };
        };
      };
    };
  };
}
