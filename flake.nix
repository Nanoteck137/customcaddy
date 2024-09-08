{
  description = "Custom Caddy with DuckDNS module";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url  = "github:numtide/flake-utils";
    dist = {
      url = "github:caddyserver/dist";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, dist, ... }:
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

          vendorHash = "sha256-/Hm2JgewdG6/h0M+IK8tHD3wSigKCzlEQIii6xFW1+E=";

          CGO_ENABLED = false;

          postBuild = ''
            dir=$GOPATH/bin
            mv $dir/customcaddy $dir/caddy
          '';

          nativeBuildInputs = [ pkgs.installShellFiles ];

          postInstall = ''
            install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

            substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
            substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"

            $out/bin/caddy manpage --directory manpages
            installManPage manpages/*

            installShellCompletion --cmd caddy \
              --bash <($out/bin/caddy completion bash) \
              --fish <($out/bin/caddy completion fish) \
              --zsh <($out/bin/caddy completion zsh)
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
