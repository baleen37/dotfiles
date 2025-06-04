{ envVar ? "USER", altVars ? ["LOGNAME" "USERNAME"] }:
let
  sudoUser = builtins.getEnv "SUDO_USER"; # original user when run via sudo
  envValue = builtins.getEnv envVar;
  fallback = builtins.foldl' (acc: var: if acc != "" then acc else builtins.getEnv var) "" altVars;
  result =
    if sudoUser != "" then sudoUser
    else if envValue != "" then envValue
    else fallback;
in
  if result != "" then result else
    builtins.throw "Environment variable ${envVar} must be set"

