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
            propagatedBuildInputs = with pkgs.python3Packages; [
              # Keep empty unless auto-detection fails for some dependency.
            ];

            # --- > Key Change Here < ---
            # Set the environment variable directly as a derivation attribute.
            # This makes it available throughout the entire build process,
            # including early PEP 517 steps like get_requires_for_build_wheel.
            # Use the *normalized* distribution name (aider-chat -> aider_chat).
            SETUPTOOLS_SCM_PRETEND_VERSION_FOR_aider_chat = version;
            # --- > End Key Change < ---


            # Tests often require extra dependencies or setup, disabled for simplicity
            doCheck = false;

            buildPhase = ''
              runHook preBuild

              # The environment variable is now set globally for the build,
              # no need to export it here again.

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
              description = "AI pair programming in your terminal";
              homepage = "https://github.com/Aider-AI/aider";
              license = licenses.asl20; # License is Apache-2.0
              maintainers = with maintainers; [ /* Your GitHub username */ ];
              platforms = platforms.unix;
            };
          };
        }
      );
    };
}
