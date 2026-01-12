{inputs, ...}: {
  flake.modules.nixos.home = {
    imports = [inputs.home-manager.nixosModules.home-manager];
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      users.z.home.stateVersion = "26.05";
    };
  };
}
