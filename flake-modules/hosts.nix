{ resolveUser, ... }:
{
  flake.hosts = {
    macbook-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = resolveUser "baleen";
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = resolveUser "baleen";
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
      homeModules = {
        # 회사 macOS는 hammerspoon / karabiner를 사용하지 않는다
        modules.programs.hammerspoon.enable = false;
        modules.programs.karabiner.enable = false;
      };
    };
    vm-aarch64-utm = {
      system = "aarch64-linux";
      class = "nixos";
      user = resolveUser "baleen";
    };
    vm-x86_64-utm = {
      system = "x86_64-linux";
      class = "nixos";
      user = resolveUser "baleen";
    };
  };
}
