{
  description = "Document containing information about Bon Accord Free Church cleaning.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-parts,
    self,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        tex = pkgs.texlive.combine {
          inherit
            (pkgs.texlive)
            scheme-minimal
            latex-bin
            latexmk
            # --- Dependencies
            datetime
            fancyhdr
            geometry
            hyperref
            kpfonts
            nth
            # --- Transative dependencies
            amsmath # nth
            fmtcount # datetime
            fontspec # kpfonts
            kpfonts-otf # kpfonts
            lualatex-math # nth
            realscripts # kpfonts
            unicode-math # nth
            xkeyval # datetime
            ;
        };

        document = pkgs.callPackage ({
          stdenvNoCC,
          writableTmpDirAsHomeHook,
          version ? self.shortRev or "dirty",
        }:
          stdenvNoCC.mkDerivation rec {
            inherit version;
            pname = "ba-church-clean-info";
            src = self;

            SOURCE_DATE_EPOCH = "${toString self.lastModified}";

            buildInputs = [
              tex
              writableTmpDirAsHomeHook
            ];

            preBuild = ''
              substituteInPlace main.tex --replace-fail "\version{}" "\version{${version}}";
            '';

            installPhase = ''
              mkdir -p $out
              cp main.pdf $out/Cleaning\ Info.pdf
            '';
          }) {};
      in {
        packages = {
          inherit document;
          default = document;
        };

        devShells.default = pkgs.mkShell {
          SOURCE_DATE_EPOCH = builtins.toString self.lastModified;
          packages = [tex];

          shellHook = ''
            echo "Welcome to LaTeX DevShell" | ${pkgs.lolcat}/bin/lolcat
          '';
        };
      };
    };
}
