{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
    "claude-code"
  ];
}
