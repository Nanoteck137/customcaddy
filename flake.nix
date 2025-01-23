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

        lib = pkgs.lib;
        stdenv = pkgs.stdenv;

        
        version = "2.8.4";
        dist = pkgs.fetchFromGitHub {
          owner = "caddyserver";
          repo = "dist";
          rev = "v${version}";
          hash = "sha256-O4s7PhSUTXoNEIi+zYASx8AgClMC5rs7se863G6w+l0=";
        };

        # From: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/ca/caddy/package.nix
        app = pkgs.buildGoModule rec {
          pname = "caddy";
          inherit version;

          src = ./.;

          vendorHash = "sha256-2QbK6DOnkyWKuMnZwiiOh5tbADBNl5kwh5kEyvmGyrk=";

          ldflags = [
            "-s" "-w"
            "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
          ];

          # matches upstream since v2.8.0
          tags = [ "nobadger" ];

          nativeBuildInputs = [ pkgs.installShellFiles ];

          postInstall = ''
            install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

            substituteInPlace $out/lib/systemd/system/caddy.service \
              --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
            substituteInPlace $out/lib/systemd/system/caddy-api.service \
              --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
          '' + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
            # Generating man pages and completions fail on cross-compilation
            # https://github.com/NixOS/nixpkgs/issues/308283

            $out/bin/caddy manpage --directory manpages
            installManPage manpages/*

            installShellCompletion --cmd caddy \
              --bash <($out/bin/caddy completion bash) \
              --fish <($out/bin/caddy completion fish) \
              --zsh <($out/bin/caddy completion zsh)
          '';

          meta = with pkgs.lib; {
            homepage = "https://caddyserver.com";
            description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
            license = licenses.asl20;
            mainProgram = "caddy";
          };        
        };
      in
      {
        packages.default = app;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
          ];
        };
      }
    );
}
