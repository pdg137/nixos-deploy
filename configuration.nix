{ ... }:

let
  hostname = "pi2";

  # Nixpkgs version to put in NIX_PATH (nixos-24.11 branch on 2024-06-06)
  # This seems redundant but we need nixpkgs, not pkgs.
  pinned-nixpkgs = fetchTarball {
    sha256 = "sha256:1rzdqgs00vzw69m569li3c6yvkdlqf7zihiivi4n83lfqginr7ar";
    url = "https://github.com/NixOS/nixpkgs/archive/0b8e7a1ae5a94da2e1ee3f3030a32020f6254105.tar.gz";
  };

  # Evalute pkgs for Raspberry Pi.
  pkgs = (import pinned-nixpkgs { system = "aarch64-linux"; }).pkgs;

  # Enable Raspberry Pi specific options under hardware.raspberry-pi."4"
  # This is the master branch on 2024-06-06.
  nixos-hardware = fetchTarball {
    sha256 = "sha256:1b893k01qaq00g09zl5f5wjnqh59xkf6h4325zq02z2zqvjcygbk";
    url = "https://github.com/NixOS/nixos-hardware/archive/d6c6cf6f5fead4057d8fb2d5f30aa8ac1727f177.tar.gz";
  };

in

{
  imports = [
    "${nixos-hardware}/raspberry-pi/4"
  ];

  nixpkgs.localSystem = {
    config = "aarch64-unknown-linux-gnu";
    system = "aarch64-linux";
  };

  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = hostname;
  };

  environment.systemPackages = with pkgs; [ vim chromium xorg.xclock ];

  services.openssh.enable = true;

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  users.mutableUsers = false;

  users.users.paul = {
    isNormalUser  = true;
    home  = "/home/paul";
    extraGroups  = [ "wheel" "networkmanager" ];
    hashedPassword = "$y$j9T$rVXspe/1Gz/1WCw/S1a3c/$jYRvKvEgTdJ.m9vzgNzsrYS5C361e5aLnSLeXKSGt9B";
    openssh.authorizedKeys.keys  = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChx7PGqR/FHqokHfuOPngrsIk6ENqMdEdZRxdPnkboo8hggPp3Dawj8uHadMqhsYgWmbgdCqHNqKAxxHF2SDrF+6I2uvLlvP+vr52MsdBXrtpgC4Y4jsMFT1vSQCGwPd3eBcgJfYg1HjxNe4SGn7p22hr8Fz2KhU1H60dpKic98s9Q8LyQBETr4MyHvPT+Xm+hMF+0E1tDGylsH/TELdkcMNGKRL0es3MCMyoKg2/hmg975uoh5VQ64SsvY1GR9d5dd3rmmiAf4DRuLAbJbFhL0rt5HvGEBsZm5BM97TqBvjTYrMIIU5wKcOE4sNGH2cgFBqJXutFqNFOAv0vZnRptAw4TM3uiwC75/zjpotvGtb6eHZK18i2G6yKWaMqahAoMslWSbW1qPe0sNdCPpVlJeXDQOM8iuhWc4e+UvAUf/1aI3l7BsPfTWWN3zwc3Wuwk5pZ6wE5sGIykIVncnwptbGLVY60rwuVgmcKaxGB+rihwg2kGi7jZKFlVL+LWwHk= paul-test" ];
  };

  nix.settings.trusted-users = [ "paul" ];

  nix.nixPath = [ "nixpkgs=${pinned-nixpkgs}:nixos-config=none" ];

  # Should be updated to match your installation
  system.stateVersion = "23.11";
}
