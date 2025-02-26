{
  description = "LLVM and Clang, Clangd";
  inputs = {
    nixpkgs.url = "github:NiOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@intputs:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {

      }

    );
}
