let
  # Nixpkgs version to use for building the profile (nixos-24.11 branch on 2024-06-06)
  pinned-nixpkgs = fetchTarball {
    sha256 = "sha256:1rzdqgs00vzw69m569li3c6yvkdlqf7zihiivi4n83lfqginr7ar";
    url = "https://github.com/NixOS/nixpkgs/archive/0b8e7a1ae5a94da2e1ee3f3030a32020f6254105.tar.gz";
  };

  # Evaluate pkgs for local system.
  pkgs = (import pinned-nixpkgs { }).pkgs;

  # Our configuration
  configuration = ./configuration.nix;

  # This locally cross-compiles the configuration for Raspberry Pi.
  profile =
    (import "${pinned-nixpkgs}/nixos" {
      configuration = "${configuration}";
      system = "aarch64-linux";
    }).config.system.build.toplevel;

  # Script that switches to the new configuration.
  rebuild-command = pkgs.writeShellScript "switch" ''
    store_path="$(dirname "$0")"
    cd $store_path

    echo "Ready to rebuild/switch to $store_path/configuration.nix."
    echo "This will also be linked as a GC root in /etc/nixos/current-configuration."
    read -p "Press enter to switch configuration..."

    rm /etc/nixos/current-configuration
    nix-store --add-root /etc/nixos/current-configuration --realize $store_path
    NIX_PATH=nixpkgs=./nixpkgs:nixos-config=./configuration.nix nixos-rebuild switch
  '';
in

  pkgs.stdenvNoCC.mkDerivation rec {
    name = "nixos-deploy";

    builder = "${pkgs.bash}/bin/bash";
    args = [ build-script ];
    src = configuration;

    build-script = pkgs.writeScript "builder.sh" ''
      source $stdenv/setup
      set -xe

      mkdir $out
      cp -r --no-preserve=mode $src $out/configuration.nix
      ln -s ${pinned-nixpkgs} $out/nixpkgs
      ln -s ${profile} $out/profile
      cp -a ${rebuild-command} $out/nixos-rebuild-switch
    '';
  }
