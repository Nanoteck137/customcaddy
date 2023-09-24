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
          version = "2.6.4";
          src = ./.;

          vendorHash = "sha256-TtOKrSeh0f74glP9fpRCYC47u8Qj2nXtzbpwFg2RLkE=";

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
