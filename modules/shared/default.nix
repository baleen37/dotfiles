# Shared modules entry point
# This file serves as the main entry point for shared modules used across different platforms

{ config, pkgs, lib, ... }:

{
  imports = [
    ./files.nix
  ];

  # Include packages directly in environment.systemPackages
  environment.systemPackages = (import ./packages.nix { inherit pkgs; });
}
