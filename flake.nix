# aider-flake.nix
# Put this file in the root of a new Git repository
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
          # Get hash using: nix-prefetch-url https://github.com/Aider-AI/aider/archive/refs/tags/v0.79.0.tar.gz
          # (Using the hash calculated previously)
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
              setuptools wheel setuptools-scm build
            ];

            # Runtime dependencies for aider v0.79.0
            # Check aider's pyproject.toml or the Nixpkgs definition for the exact list
            propagatedBuildInputs = with pkgs.python3Packages; [
              openai
              tiktoken
              python-dotenv
              pyyaml
              rich
              gitpython # Provides 'git' module
              diff-match-patch
              inquirer
            ];

            # Workaround for setuptools-scm needing version info from non-git source
            SETUPTOOLS_SCM_PRETEND_VERSION_FOR_aider_chat = aiderVersion;

            # Skip tests for now
            doCheck = false;

            # Standard build and install phases for PEP517/wheels
            buildPhase = ''
              runHook preBuild
              python -m build --wheel --no-isolation
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              pip install dist/*.whl --prefix=$out
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "AI pair programming in your terminal (v${aiderVersion})";
              homepage = "https://github.com/Aider-AI/aider";
              license = licenses.asl20; # Apache 2.0
              platforms = platforms.unix;
            };
          };

          # Make 'aider' the default package for this flake
          default = self.packages.${system}.aider;
        }
      );

      # You could add other outputs here like checks, devShells, etc.
      # Example devShell:
      # devShells = forAllSystems (system: {
      #   default = pkgsFor system.mkShell {
      #      packages = [ self.packages.${system}.aider ];
      #   };
      # });
    };
}
