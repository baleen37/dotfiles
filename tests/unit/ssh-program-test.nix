{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hm = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/ssh.nix
      {
        home = {
          username = "testuser";
          homeDirectory = "/home/testuser";
          stateVersion = "24.11";
        };
        modules.programs.ssh.enable = true;
      }
    ];
  };

  ssh = hm.config.programs.ssh;
  configText = hm.config.home.file.".ssh/config".text;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "ssh-program" [
    (helpers.assertTest "ssh-program-no-deprecation-warnings" (
      hm.config.warnings == [ ]
    ) "SSH configuration should not use deprecated Home Manager options")

    (helpers.assertTest "ssh-program-no-match-blocks" (
      ssh.matchBlocks == { }
    ) "SSH configuration should use programs.ssh.settings instead of matchBlocks")

    (helpers.assertTest "ssh-program-default-config-disabled" (
      ssh.enableDefaultConfig == false
    ) "SSH default compatibility config should be disabled and copied explicitly")

    # Interval x CountMax is how long a silent connection survives. A remote job
    # that prints nothing until it finishes generates no traffic, so too short a
    # window lets a NAT/firewall reap the session mid-run. Assert the product,
    # not just the presence of the directives.
    (helpers.assertTest "ssh-program-keepalive-setting" (
      ssh.settings."*".data.ServerAliveInterval * ssh.settings."*".data.ServerAliveCountMax >= 300
      && ssh.settings."*".data.ServerAliveInterval <= 30
      && ssh.settings."*".data.TCPKeepAlive == "yes"
    ) "SSH keepalive must tolerate at least 5 minutes of silence, probing at most every 30s")

    (helpers.assertTest "ssh-program-github-setting" (
      ssh.settings."github.com".data.HostName == "github.com"
      && ssh.settings."github.com".data.User == "git"
      && ssh.settings."github.com".data.StrictHostKeyChecking == "no"
    ) "GitHub SSH settings should use OpenSSH directive names")

    (helpers.assertTest "ssh-program-generated-config" (
      lib.hasInfix "Include ~/.orbstack/ssh/config" configText
      && lib.hasInfix "Host github.com" configText
      && lib.hasInfix "StrictHostKeyChecking no" configText
      && lib.hasInfix "Host *" configText
      && lib.hasInfix "ServerAliveInterval 15" configText
      && lib.hasInfix "TCPKeepAlive yes" configText
    ) "Generated ~/.ssh/config should keep the existing behavior")
  ];
}
