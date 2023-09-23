{
  description = "Custom Caddy with DuckDNS module";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        app = pkgs.buildGoModule {
          pname = "caddy";
          version = "0.0.1";
          src = ./.;

          vendorHash = "sha256-w0DlIcya8PzKHMhG6TI7EJeROMDOAU+XsP9Bep7woLw=";

          CGO_ENABLED = false;

          postBuild = ''
            dir=$GOPATH/bin
            mv $dir/customcaddy $dir/caddy
          '';
        };
      in
      {
        packages.default = app;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go_1_20
            gopls
          ];
        };
      }
    );
}
