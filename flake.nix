{
  description = "flake for development of bisect_ppx";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      buildInputs = with pkgs; [ git dune_2 ocaml ocamlformat ] ++ (with ocamlPackages;
          [
            findlib # Just so that ocaml can discover the libraries given in the environment
            ppxlib cmdliner # dependencies of bisect_ppx
          ]);
    in {
      devShells.${system}.default = pkgs.mkShell {
        name = "bisect_ppx-development";
        buildInputs = buildInputs;
      };
      packages.${system} = {
        default = pkgs.stdenv.mkDerivation {
          name = "Build and test";
          buildInputs = buildInputs;
          buildPhase = "make test";
          installPhase = "mkdir -p $out";
        };
        rescript = pkgs.stdenv.mkDerivation {
          name = "Try rescript";
          buildInputs = buildInputs;
          buildPhase = "make test && make -C test/js full-test";
        };
      };
    };
}
