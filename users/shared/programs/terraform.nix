# Terraform CLI configuration
#
# A shared provider plugin cache, so every worktree's .terraform/providers is
# a symlink into one cache instead of its own copy. Terraform only reuses a
# cached provider whose checksum matches .terraform.lock.hcl, and the cache is
# not safe for concurrent `terraform init` runs.
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.terraform;
  pluginCacheDir = "${config.home.homeDirectory}/.terraform.d/plugin-cache";
in
{
  options.modules.programs.terraform.enable = lib.mkEnableOption "Terraform CLI configuration" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.file.".terraformrc".text = ''
      plugin_cache_dir = "${pluginCacheDir}"
    '';

    # Terraform ignores plugin_cache_dir when the directory does not exist.
    home.activation.terraformPluginCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg pluginCacheDir}
    '';
  };
}
