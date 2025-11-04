{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-step-fork.url = "github:rv32ima/nixpkgs?ref=rv32ima/fix-broken-status-darwin";
  };

  outputs =
    inputs@{ ... }:
    let
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
      };
      pkgsStepFork = import inputs.nixpkgs-step-fork {
        system = "aarch64-darwin";
      };
    in
    {
      devShells.aarch64-darwin.default = pkgs.mkShell {
        packages = with pkgs; [
          tenv
          
          step-cli
          pkgsStepFork.step-kms-plugin
        ];
      };
    };
}
