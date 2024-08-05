# SPDX-FileCopyrightText: 2024 Christina Sørensen
# SPDX-FileContributor: Christina Sørensen
#
# SPDX-License-Identifier: EUPL-1.2
{
  description = "ha-registry: High Availability Container Registry";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

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

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
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
    nixpkgs,
    treefmt-nix,
    rust-overlay,
    pre-commit-hooks,
    crane,
    fenix,
    advisory-db,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];

        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        inherit (pkgs) lib;

        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
        src = craneLib.cleanCargoSource (craneLib.path ./.);

        darwinBuildInputs = with pkgs; with darwin.apple_sdk.frameworks; [libiconv Security SystemConfiguration];

        # Common arguments can be set here to avoid repeating them later
        commonArgs = {
          inherit src;
          strictDeps = true;

          buildInputs = with pkgs;
            [
              # Add additional build inputs here
              openssl
            ]
            ++ lib.optionals pkgs.stdenv.isDarwin darwinBuildInputs;

          # Additional environment variables can be set directly
          # MY_CUSTOM_VAR = "some value";

          nativeBuildInputs = with pkgs; [
            makeWrapper
            installShellFiles
            pkg-config
          ];
        };

        craneLibLLvmTools =
          craneLib.overrideToolchain
          (fenix.packages.${system}.complete.withComponents [
            "cargo"
            "llvm-tools"
            "rustc"
          ]);

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        ha-registry = craneLib.buildPackage (commonArgs
          // {
            inherit cargoArtifacts;

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

            meta.mainProgram = "ha-registry";
          });

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in rec {
        # For `nix fmt`
        formatter = treefmtEval.config.build.wrapper;

        packages =
          {
            default = ha-registry;

            container = pkgs.dockerTools.buildLayeredImage {
              name = "ha-tregistry";
              tag = "latest";
              contents = [packages.default pkgs.cacert];
              config = {
                Labels = {
                  "org.opencontainers.image.source" = "https://github.com/cafkafk/ha-registry";
                  "org.opencontainers.image.description" = "ha-registry: High Availability Container Registry";
                  "org.opencontainers.image.license" = "EUPL-1.2";
                };
                Env = [
                  "RUST_LOG=trace"
                ];
                Cmd = ["/bin/ha-registry"];
              };
            };

            distribution-spec = pkgs.buildGoModule rec {
              name = "distribution-spec";
              version = "1.1.0";

              src = pkgs.fetchFromGitHub {
                owner = "opencontainers";
                repo = "distribution-spec";
                rev = "v${version}";
                hash = "sha256-GL28YUwDRicxS65E7SDR/Q3tJOWN4iwgq4AGBjwVPzA=";
              };

              buildPhase = ''
                go test -c -o conformance.test
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp conformance.test $out/bin
              '';

              vendorHash = "sha256-5gn9RpjCALZB/GFjlJHDqPs2fIHl7NJr5QjPmsLnnO4=";
              modRoot = "conformance";
            };
          }
          // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
            serde-yaml-llvm-coverage = craneLibLLvmTools.cargoLlvmCov (commonArgs
              // {
                inherit cargoArtifacts;
              });
          };

        apps.default = flake-utils.lib.mkApp {
          drv = ha-registry;
        };

        # For `nix develop`:
        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";
          packages = with pkgs; [rustup toolchain cargo-deny just zip reuse pkg-config openssl statix convco] ++ self.checks.${system}.pre-commit-check.enabledPackages;
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        # For `nix flake check`
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          inherit ha-registry;

          # Run clippy (and deny all warnings) on the crate source,
          # again, reusing the dependency artifacts from above.
          #
          # Note that this is done as a separate derivation so that
          # we can block the CI if there are issues here, but not
          # prevent downstream consumers from building our crate by itself.
          ha-registry-clippy = craneLib.cargoClippy (commonArgs
            // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            });

          ha-registry-doc = craneLib.cargoDoc (commonArgs
            // {
              inherit cargoArtifacts;
            });

          # Check formatting
          ha-registry-fmt = craneLib.cargoFmt {
            inherit src;
          };

          # Audit dependencies
          ha-registry-audit = craneLib.cargoAudit {
            inherit src advisory-db;
          };

          # Audit licenses
          ha-registry-deny = craneLib.cargoDeny {
            inherit src;
          };

          # Run tests with cargo-nextest
          # Consider setting `doCheck = false` on `ha-registry` if you do not want
          # the tests to run twice
          ha-registry-nextest = craneLib.cargoNextest (commonArgs
            // {
              inherit cargoArtifacts;
              partitions = 1;
              partitionType = "count";
            });

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
        };
      }
    )
    // {
      nixosModules = {
        ha-registry = {imports = [./nixos/modules/ha-registry.nix];};
      };
    };
}
