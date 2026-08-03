_:
{
  flake.hosts = {
    macbook-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
    };
    vm-aarch64-utm = {
      system = "aarch64-linux";
      class = "nixos";
      user = "baleen";
    };
    vm-x86_64-utm = {
      system = "x86_64-linux";
      class = "nixos";
      user = "baleen";
    };
  };
}
