{ pkgs, ... }: {
  switch = import ./switch.nix { inherit pkgs; };
}
