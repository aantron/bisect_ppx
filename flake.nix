{
  description = "flake for development of bisect_ppx";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      buildInputs = with pkgs; [
        git
        glibc # Something to do with esy
        dune_2
        ocamlformat_0_16_0 # ci currently tests with ocamlformat 0.16
      ] ++ (with ocaml-ng.ocamlPackages_4_13;
          [
            ocaml
            findlib # Just so that ocaml can discover the libraries given in the environment
            ppxlib cmdliner # dependencies of bisect_ppx
            js_of_ocaml
          ]);
    in {
      devShells.${system}.default = pkgs.mkShell {
        name = "bisect_ppx-development";
        buildInputs = buildInputs;
      };
      packages.${system} = {
        default = pkgs.stdenv.mkDerivation {
          name = "bisect_ppx - build and test";
          src = ./.;
          buildInputs = buildInputs;
          buildPhase = "make test";
          installPhase = "mkdir -p $out";
        };
        # This requires internet access
       # rescript = pkgs.stdenv.mkDerivation {
       #   src = ./.;
       #   name = "bisect_ppx - test rescript";
       #   buildInputs = buildInputs;
       #   buildPhase = "make build && make -C test/js full-test";
       #   installPhase = "mkdir -p $out";
       # };
      };
    };
}
