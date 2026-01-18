{
  perSystem = {pkgs, ...}: {
    devShells = {
      go = pkgs.mkShell {
        packages = with pkgs; [
          go
          gofumpt
          gopls
        ];
      };
      rust = pkgs.mkShell {
        packages = with pkgs; [
          rustc
          cargo
          rust-analyzer
        ];
      };
    };
  };
}
