{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
    # unfree packages are listed here when needed
  ];
}
