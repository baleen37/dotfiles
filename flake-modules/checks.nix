{ inputs, self, ... }:

{
  perSystem =
    { system, ... }:
    {
      checks = import ../tests { inherit system inputs self; };
    };
}
