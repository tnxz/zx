{lib, ...}: {
  flake.modules.nixos.init = {
    imports = [/etc/nixos/configuration.nix];

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    programs.ssh.knownHosts."github.com" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };

    nix.settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["@wheel"];
      substituters = ["https://nix-community.cachix.org"];
      trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
      auto-optimise-store = true;
      use-xdg-base-directories = true;
    };

    users.users.root.hashedPassword = "$y$j9T$TbCITHWCt4h.bqA.bjonU1$lLvb.iUoosXHMh5It5sBDagI8wNLTCjjlXSOn7972Q8";

    users.users.z.hashedPassword = "$y$j9T$BB1VA7OYSTws6jviRuMBq.$84IfAZxUlUM0FMglOABz4xUmxwn3izh8UAARkFbBMw9";
  };
}
