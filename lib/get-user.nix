{ envVar ? "USER", default ? null }:
let
  envValue = builtins.getEnv envVar; # read from USER environment variable
  sudoUser = builtins.getEnv "SUDO_USER"; # get original user when using sudo
in
  if sudoUser != "" then sudoUser
  else if envValue != "" then envValue
  else if default != null then default
  else builtins.throw "Environment variable ${envVar} must be set"
