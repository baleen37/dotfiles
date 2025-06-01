self: super: {
  # 예시: my-patched-htop = super.htop.overrideAttrs (oldAttrs: {
  #   patches = (oldAttrs.patches or []) ++ [ ./my-htop-patch.patch ];
  # });
}
