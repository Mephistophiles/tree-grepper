{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nmattia/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # tree-sitter grammars
    tree-sitter-c = {
      url = "github:tree-sitter/tree-sitter-c";
      flake = false;
    };

    tree-sitter-cpp = {
      url = "github:tree-sitter/tree-sitter-cpp";
      flake = false;
    };

    tree-sitter-nix = {
      url = "github:cstrahan/tree-sitter-nix";
      flake = false;
    };

    tree-sitter-elixir = {
      url = "github:elixir-lang/tree-sitter-elixir/main";
      flake = false;
    };

    tree-sitter-elm = {
      url = "github:elm-tooling/tree-sitter-elm/main";
      flake = false;
    };

    tree-sitter-haskell = {
      url = "github:tree-sitter/tree-sitter-haskell";
      flake = false;
    };

    tree-sitter-javascript = {
      url = "github:tree-sitter/tree-sitter-javascript";
      flake = false;
    };

    tree-sitter-markdown = {
      url = "github:ikatyang/tree-sitter-markdown";
      flake = false;
    };

    tree-sitter-php = {
      url = "github:tree-sitter/tree-sitter-php";
      flake = false;
    };

    tree-sitter-ruby = {
      url = "github:tree-sitter/tree-sitter-ruby";
      flake = false;
    };

    tree-sitter-rust = {
      url = "github:tree-sitter/tree-sitter-rust";
      flake = false;
    };

    tree-sitter-typescript = {
      url = "github:tree-sitter/tree-sitter-typescript";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
        naersk-lib = inputs.naersk.lib."${system}";
        darwinInputs = if pkgs.stdenv.isDarwin then [ pkgs.xcbuild ] else [ ];

        updateVendor = pkgs.writeShellScriptBin "update-vendor" ''
          set -euo pipefail

          rm -rf vendor
          mkdir vendor

          set -x
          ln -s ${inputs.tree-sitter-c} vendor/tree-sitter-c
          ln -s ${inputs.tree-sitter-cpp} vendor/tree-sitter-cpp
          ln -s ${inputs.tree-sitter-elixir} vendor/tree-sitter-elixir
          ln -s ${inputs.tree-sitter-elm} vendor/tree-sitter-elm
          ln -s ${inputs.tree-sitter-haskell} vendor/tree-sitter-haskell
          ln -s ${inputs.tree-sitter-javascript} vendor/tree-sitter-javascript
          ln -s ${inputs.tree-sitter-markdown} vendor/tree-sitter-markdown
          ln -s ${inputs.tree-sitter-php} vendor/tree-sitter-php
          ln -s ${inputs.tree-sitter-ruby} vendor/tree-sitter-ruby
          ln -s ${inputs.tree-sitter-rust} vendor/tree-sitter-rust
          ln -s ${inputs.tree-sitter-typescript} vendor/tree-sitter-typescript
          ln -s ${inputs.tree-sitter-nix} vendor/tree-sitter-nix
        '';
      in rec {
        # `nix build`
        packages.tree-grepper = naersk-lib.buildPackage {
          root = ./.;
          buildInputs = [ pkgs.libiconv pkgs.rustPackages.clippy ]
            ++ darwinInputs;

          preBuildPhases = [ "vendorPhase" ];
          vendorPhase = "${updateVendor}/bin/update-vendor";

          doCheck = true;
          checkPhase = ''
            cargo test
            cargo clippy -- --deny warnings
          '';
        };
        defaultPackage = packages.tree-grepper;
        overlay = final: prev: { tree-grepper = packages.tree-grepper; };

        # `nix develop`
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              cargo
              cargo-edit
              # https://github.com/NixOS/nixpkgs/issues/146349
              # cargo-watch
              rustPackages.clippy
              rustc
              rustfmt

              updateVendor

              # for some reason this seems to be required, especially on macOS
              libiconv
            ] ++ darwinInputs;
        };
      });
}
