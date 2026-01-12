{inputs, ...}: {
  flake.modules.nixos.sops = {
    config,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [sops age ssh-to-age];

    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = "${inputs.secrets}/secrets.yaml";
      age.sshKeyPaths = [
        "${config.users.users.z.home}/.ssh/id_ed25519"
      ];
      age.generateKey = false;
      secrets.gh_token = {owner = "z";};
    };

    environment.sessionVariables = {
      SOPS_AGE_KEY = "$(ssh-to-age -private-key -i ${
        builtins.head config.sops.age.sshKeyPaths
      })";
      GH_TOKEN = "$(cat ${config.sops.secrets.gh_token.path})";
    };
  };
}
