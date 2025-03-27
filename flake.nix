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
            pname = "aider"; # The package name in Nixpkgs
            version = "0.79.0";
            src = aider-src;

            format = "pyproject"; # Indicates pyproject.toml is used

            # Build-time dependencies needed to build the package/wheel
            nativeBuildInputs = with pkgs.python3Packages; [
              setuptools      # Core build tool
              wheel           # For building wheels
              setuptools-scm  # Needed by aider's build process, even if we override version
              build           # Modern PEP 517 build frontend (used in buildPhase)
            ];

            # Runtime dependencies - Nix usually auto-detects these from the wheel.
            # Keep empty unless auto-detection fails for some dependency.
            propagatedBuildInputs = with pkgs.python3Packages; [
              # Example: if 'requests' was needed at runtime and not detected:
              # requests
            ];

            # Tests often require extra dependencies or setup, disabled for simplicity
            doCheck = false;

            buildPhase = ''
              runHook preBuild

              # Tell setuptools-scm the version since we don't have .git metadata
              # Use the *normalized* distribution name (aider-chat -> aider_chat)
              export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_aider_chat=${version}

              # Build the wheel using the 'build' package
              # --no-isolation uses the environment Nix set up, which is correct here
              python -m build --wheel --no-isolation

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              # Install the wheel built in the buildPhase into the $out directory
              pip install dist/*.whl --prefix=$out

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "AI pair programming in your terminal"; # Updated description from repo
              homepage = "https://github.com/Aider-AI/aider";
              license = licenses.asl20; # License is Apache-2.0 according to repo/PyPI
              maintainers = with maintainers; [ /* Your GitHub username */ ]; # Optional: add yourself
              platforms = platforms.unix; # Runs on linux and darwin
            };
          };
        }
      );
    };
}
