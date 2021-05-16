{
  description = "A Coq formalization of information theory and linear error correcting codes";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, nixpkgs-unstable }:
    let
      nixpkgs = nixpkgs-unstable; # default nixpkgs
      flib = flake-utils.lib;

      name = "infotheo";

      systems = flib.defaultSystems;

      overlay = final: prev: {

        ${name} = with final; let
          legacyPackages = final.${name};
          coqPackages = coqPackages_8_13;
          inherit (coqPackages) coq;
        in {
          nixpkgs = final;

          devEnv = buildEnv {
            name = "${name}-dev-env";
            paths = [ git ] ++ legacyPackages.${name}.buildInputs;
          };

          devShell = mkShell { buildInputs = [ legacyPackages.devEnv ]; };

          defaultPackage = legacyPackages.${name};
          ${name} = lib.flip coqPackages.callPackage {} (
            { lib, coq, mkCoqDerivation, mathcomp, mathcomp-analysis }:
            with lib;
            assert with versions;
              isEq "8.13" coq.version
              && isEq "1.12.0" mathcomp.version
              && isGe "0.3.6" mathcomp-analysis.version;
            mkCoqDerivation {
              pname = "infotheo";
              owner = "affeldt-aist";

              version = ./.;

              propagatedBuildInputs = attrValues {
                inherit mathcomp-analysis;
                inherit (mathcomp) ssreflect fingroup algebra solvable field;
              };

              meta = {
                description = "A Coq formalization of information theory and linear error correcting codes";
                license = licenses.lgpl2Plus;
              };
            }
          );
        };
      };

      mkFlake = nixpkgs: flib.simpleFlake {
        inherit self nixpkgs name systems overlay;
      };

      defaultFlake = mkFlake nixpkgs;
      unstable = mkFlake nixpkgs-unstable;
    in
    defaultFlake // { inherit overlay; } // flib.eachDefaultSystem (system: {
      legacyPackages = {
        default = defaultFlake.legacyPackages.${system};
        unstable = unstable.legacyPackages.${system};
      };

      packages = with nixpkgs.lib;
        filterAttrs (n: v: isDerivation v) self.legacyPackages.${system}.default;
    });

}
