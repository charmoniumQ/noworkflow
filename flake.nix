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

        sqlalchemy_1 = python.pkgs.sqlalchemy.overrideAttrs rec {
          version = "1.4.54";
          src = pkgs.fetchFromGitHub {
            owner = "sqlalchemy";
            repo = "sqlalchemy";
            tag = "rel_${pkgs.lib.replaceStrings [ "." ] [ "_" ] version}";
            hash = "sha256-6qAjyqMVrugABHssAQuql3z1YHTAOSm5hARJuJXJJvo=";
          };
          disabledTestPaths = [
            # typing correctness, not interesting
            #"test/ext/mypy" (not present in 1.x)
            #"test/typing"

            # slow and high memory usage, not interesting
            "test/aaa_profiling"
          ];
        };

        noworkflow = python.pkgs.buildPythonPackage rec {
          pname = "noworkflow";
          version = "dev";
          src = ./.;
          pyproject = true;
          dependencies = [
            pyposast
            sqlalchemy_1
            python.pkgs.apted
            python.pkgs.future
            python.pkgs.parameterized
            python.pkgs.requests
            python.pkgs.ipykernel
            python.pkgs.zipp
            python.pkgs.importlib-metadata
            python.pkgs.typing-extensions
            python.pkgs.setuptools
            python.pkgs.pandas
            python.pkgs.nbformat
          ];
          build-system = [
            python.pkgs.setuptools
          ];
          pythonImportsCheck = [
            pname
          ];
        };
        noworkflow-bin = pkgs.runCommand "noworkflow-bin" { } ''
          mkdir --parents $out/bin
          ln --symbolic ${noworkflow}/bin/now $out/bin/now
        '';
      in rec {
        packages = rec {
            inherit noworkflow noworkflow-bin pyposast;
        };
      }
    );
}
