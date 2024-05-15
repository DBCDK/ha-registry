# SPDX-FileCopyrightText: 2024 Christina Sørensen
# SPDX-FileContributor: Christina Sørensen
#
# SPDX-License-Identifier: AGPL-3.0-only
 
{
  description = "ha-registry: High Availability Container Registry";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";

    systems.url = "github:nix-systems/default";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    naersk = {
      url = "github:nix-community/naersk";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };
  };

  outputs = {
    self,
    flake-utils,
    naersk,
    nixpkgs,
    treefmt-nix,
    rust-overlay,
    pre-commit-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];

        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        naersk' = pkgs.callPackage naersk {
          cargo = toolchain;
          rustc = toolchain;
          clippy = toolchain;
        };

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        darwinBuildInputs = with pkgs; with darwin.apple_sdk.frameworks; [libiconv Security SystemConfiguration];

        buildInputs = with pkgs; [pkg-config openssl] ++ lib.optionals stdenv.isDarwin darwinBuildInputs;
      in rec {
        # For `nix fmt`
        formatter = treefmtEval.config.build.wrapper;

        packages = {
          # For `nix build` & `nix run`:
          default = naersk'.buildPackage {
            src = ./.;
            doCheck = true; # run `cargo test` on build
            copyBins = true;
            copyLibs = true;
            singleStep = true;
            inherit buildInputs;

            nativeBuildInputs = with pkgs; [makeWrapper installShellFiles];

            MAN_OUT = "./man";

            preBuild = ''
              mkdir -p "./$MAN_OUT";
            '';

            preInstall = ''
              installManPage man/ha-registry.1
              installShellCompletion \
                --fish man/ha-registry.fish \
                --bash man/ha-registry.bash \
                --zsh  man/_ha-registry
              mkdir -p $out
            '';
          };

          container = pkgs.dockerTools.buildLayeredImage {
            name = "ha-tregistry";
            tag = "latest";
            contents = [packages.default pkgs.cacert];
            config = {
              Labels = {
                "org.opencontainers.image.source" = "https://github.com/cafkafk/ha-registry";
                "org.opencontainers.image.description" = "ha-registry: High Availability Container Registry";
                "org.opencontainers.image.license" = "AGPL-3.0-only";
              };
              Env = [
                "RUST_LOG=trace"
              ];
              Cmd = ["/bin/ha-registry"];
            };
          };

          # Run `nix build .#check` to check code
          check = naersk'.buildPackage {
            src = ./.;
            mode = "check";
            inherit buildInputs;
          };

          # Run `nix build .#test` to run tests
          test = naersk'.buildPackage {
            src = ./.;
            mode = "test";
            inherit buildInputs;
          };

          # Run `nix build .#clippy` to lint code
          clippy = naersk'.buildPackage {
            src = ./.;
            mode = "clippy";
            inherit buildInputs;
          };
        };

        # For `nix develop`:
        devShells.default = pkgs.mkShell {
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          nativeBuildInputs = with pkgs; [rustup toolchain just zip reuse pkg-config openssl vhs fish statix clippy];
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        # For `nix flake check`
        checks = {
          status = pkgs.callPackage ./nixos/tests/status.nix {inherit packages;};
          pre-commit-check = let
            # some treefmt formatters are not supported in pre-commit-hooks we filter them out for now.
            toFilter = ["yamlfmt"];
            filterFn = n: _v: (!builtins.elem n toFilter);
            treefmtFormatters = pkgs.lib.mapAttrs (_n: v: {inherit (v) enable;}) (pkgs.lib.filterAttrs filterFn (import ./treefmt.nix).programs);
          in
            pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks =
                treefmtFormatters
                // {
                  convco.enable = true; # not in treefmt
                  reuse = {
                    enable = true;
                    name = "reuse";
                    entry = with pkgs; "${pkgs.reuse}/bin/reuse lint";
                    pass_filenames = false;
                  };
                };
            };
          formatting = treefmtEval.config.build.check self;
          build = packages.check;
          inherit
            (packages)
            default
            test
            ;
          lint = packages.clippy;
        };
      }
    )
    // {
      nixosModules = {
        ha-registry = {imports = [./nixos/modules/ha-registry.nix];};
      };
    };
}
