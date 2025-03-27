{
  description = "A Nix flake for packaging aider-chat";
  inputs = {
    # Pin nixpkgs for reproducibility
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      # Define the specific version you want to package
      aiderVersion = "0.79.0";
      # Systems to build for
      supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      # Helper function to generate outputs for all supported systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      # Get the package set for a specific system
      pkgsFor = system: import nixpkgs {
        inherit system;
        # overlays = []; # Add overlays if needed
      };
    in {
      # Provide the package for each system
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          # Fetch aider source tarball from GitHub release tag
          aiderSrc = pkgs.fetchFromGitHub {
            owner = "Aider-AI";
            repo = "aider";
            rev = "v${aiderVersion}";
            hash = "sha256-1PjQP3SQ1qiV/IShTvA3VCjUkzaziUZpL5gLS217NUQ=";
          };
        in {
          # The actual package definition
          aider = pkgs.python3Packages.buildPythonApplication {
            pname = "aider";
            version = aiderVersion;
            src = aiderSrc;
            format = "pyproject";

            # Build-time dependencies
            nativeBuildInputs = with pkgs.python3Packages; [
              setuptools
              wheel
              setuptools-scm
              build
            ];

            # Runtime dependencies for aider v0.79.0
            propagatedBuildInputs = with pkgs.python3Packages; [
              openai
              tiktoken
              python-dotenv
              pyyaml
              rich
              gitpython
              diff-match-patch
              inquirer
            ];

            # Explicitly set the version to avoid setuptools-scm issues
            SETUPTOOLS_SCM_PRETEND_VERSION = aiderVersion;

            # More robust build and install phases
            buildPhase = ''
              runHook preBuild
              export SETUPTOOLS_SCM_PRETEND_VERSION=${aiderVersion}
              python -m build --wheel --no-isolation
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              python -m pip install dist/*.whl --prefix=$out
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "AI pair programming in your terminal (v${aiderVersion})";
              homepage = "https://github.com/Aider-AI/aider";
              license = licenses.asl20;
              platforms = platforms.unix;
            };
          };

          # Make 'aider' the default package for this flake
          default = self.packages.${system}.aider;
        }
      );
    };
}

