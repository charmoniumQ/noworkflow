{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: flake-utils.lib.eachDefaultSystem
    (system: let
        pkgs = import nixpkgs {inherit system;};
        python = pkgs.python312;

        pyposast = python.pkgs.buildPythonPackage rec {
          pname = "PyPosAST";
          version = "1.6.2";
          src = pkgs.fetchFromGitHub {
            owner = "JoaoFelipe";
            repo = "pyposast";
            rev = version;
            hash = "sha256-daKpI92dV+H24TwjrQUazCpb/FbPAJzLld7SdQtkoOA=";
          };
          pyproject = true;
          build-system = [
            python.pkgs.setuptools
          ];
          nativeBuildInputs = [
            pkgs.git
          ];
        };

        noworkflow = python.pkgs.buildPythonPackage rec {
          pname = "noworkflow";
          version = "dev";
          src = ./.;
          pyproject = true;
          dependencies = [
            pyposast
            python.pkgs.apted
            python.pkgs.future
            python.pkgs.sqlalchemy
            python.pkgs.parameterized
            python.pkgs.requests
            python.pkgs.ipykernel
            python.pkgs.zipp
            python.pkgs.importlib-metadata
            python.pkgs.typing-extensions
          ];
          build-system = [
            python.pkgs.setuptools
          ];
        };
      in rec {
        packages = rec {
            inherit noworkflow pyposast;
        };
      }
    );
}
