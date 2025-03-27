{
  description = "Aider v0.79.0 packaged from GitHub without git metadata";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aider-src = {
      url = "github:Aider-AI/aider/v0.79.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, aider-src }:
    let
      supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.python3Packages.buildPythonApplication {
            pname = "aider";
            version = "0.79.0";
            src = aider-src;

            format = "pyproject";

            nativeBuildInputs = with pkgs.python3Packages; [
              setuptools
              wheel
              setuptools-scm
              build
            ];

            propagatedBuildInputs = with pkgs.python3Packages; [
              setuptools
              wheel
              setuptools-scm
            ];

            doCheck = false;

            # This line explicitly tells setuptools-scm the version
            SETUPTOOLS_SCM_PRETEND_VERSION = "0.79.0";

            buildPhase = ''
              export SETUPTOOLS_SCM_PRETEND_VERSION=${version}
              python -m build --wheel --no-isolation
            '';

            installPhase = ''
              pip install dist/*.whl --prefix=$out
            '';

            meta = with pkgs.lib; {
              description = "AI-powered coding assistant";
              homepage = "https://github.com/Aider-AI/aider";
              license = licenses.mit;
            };
          };
        }
      );
    };
}=
