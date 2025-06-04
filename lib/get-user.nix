{ envVar ? "USER" }:
let
  envValue = builtins.getEnv envVar; # read from USER environment variable
in
  if envValue != "" then envValue else
    builtins.throw "Environment variable ${envVar} must be set"
