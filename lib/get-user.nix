{ envVar ? "USER", default ? null }:
let
  envValue = builtins.getEnv envVar; # read from USER environment variable
in
  if envValue != "" then envValue
  else if default != null then default
  else builtins.throw "Environment variable ${envVar} must be set"
