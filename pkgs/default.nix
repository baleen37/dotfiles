pkgs: {
  bootstrap-tools = pkgs.buildEnv {
    name = "dotfiles-bootstrap-tools";
    paths = with pkgs; [
      coreutils
      jq
      git
      age
      sops
      _1password-cli
    ];
  };
}
