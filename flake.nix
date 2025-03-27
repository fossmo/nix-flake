{
  description = "Aider v0.79.0 packaged from GitHub";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aider-src = {
      url = "github:Aider-AI/aider/v0.79.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, aider-src }:
    let
      system = "x86_64-linux"; # Change if needed
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.python3Packages.buildPythonApplication {
        pname = "aider";
        version = "0.79.0";
        src = aider-src;

        propagatedBuildInputs = with pkgs.python3Packages; [
          setuptools
          wheel
        ];

        doCheck = false;

        meta = with pkgs.lib; {
          description = "AI-powered coding assistant";
          homepage = "https://github.com/Aider-AI/aider";
          license = licenses.mit;
        };
      };
    };
}
