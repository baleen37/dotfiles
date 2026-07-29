# tests/lib/mock-config.nix
#
# Minimal stand-in for the `config` argument when a Home Manager module is
# imported directly rather than through lib.evalModules.
#
# Modules that read `config.home.*` need those attributes to exist; anything a
# specific test cares about is layered on top at the call site, e.g.
#
#   config = mockConfig.mkEmptyConfig // { modules.programs.starship.enable = true; };

_:

{
  mkEmptyConfig = {
    home = {
      username = "testuser";
      homeDirectory = "/home/testuser";
    };
  };
}
