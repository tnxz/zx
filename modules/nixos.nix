{
  lib,
  self,
  config,
  ...
}: {
  flake.nixosConfigurations.zx = lib.nixosSystem {
    modules = with self.modules.nixos;
      [
        init
        sops
        tools
        home
      ]
      ++ [
        {
          home-manager.users.z.imports = with config.flake.modules.homeManager; [
            nvim
            tools
          ];
        }
      ];
  };
}
