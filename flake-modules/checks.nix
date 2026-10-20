{ inputs, self, ... }:

{
  perSystem =
    { system, pkgs, ... }:
    {
      checks = import ../tests {
        inherit
          system
          inputs
          self
          pkgs
          ;
      };
    };
}
