# Simple test VM configuration
{
  programs.qemu-vm = {
    enable = true;

    vms = {
      test-vm = {
        name = "test-vm";
        memory = 1024;
        cores = 1;
        diskSize = "8G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = false;
        display = "none";
        enableKvm = false;
      };
    };
  };

  home.packages = [ ];
}
