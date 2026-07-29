# tests/lib/plugin-test-helpers.nix
#
# Predicates for the two shapes that plugin-based programs (vim, tmux) expose:
# a list of plugin derivations, and a blob of generated config text.
#
# These return booleans rather than test derivations so a caller can combine
# several of them inside one assertTest and get a single, meaningful failure.
{
  lib,
  ...
}:

rec {
  # Plugins are derivations; `pname` is the upstream name (e.g. "vim-airline").
  hasPluginByName = plugins: pname: builtins.any (plugin: (plugin.pname or null) == pname) plugins;

  hasConfigPattern = config: pattern: builtins.match pattern config != null;

  hasConfigString = config: str: lib.hasInfix str config;

  hasAllConfigPatterns = config: patterns: lib.all (hasConfigPattern config) patterns;
}
