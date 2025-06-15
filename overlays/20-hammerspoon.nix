self: super: with super; {
  hammerspoon = let
    version = "1.0.0";
    pname = "hammerspoon";
  in stdenv.mkDerivation {
    name = "${pname}-${version}";

    src = fetchzip {
      url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${version}/Hammerspoon-${version}.zip";
      sha256 = "0zkagvnzf2ia68l998nzblqvvgl5xy8qv57mx03c6zd4bnsh5dsx";
    };

    buildInputs = [ unzip ];
    phases = [ "unpackPhase" "installPhase" ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/Applications/Hammerspoon.app
      cp -R . $out/Applications/Hammerspoon.app
    '';

    meta = with lib; {
      homepage = "http://www.hammerspoon.org/";
      description = "Staggeringly powerful macOS desktop automation with Lua";
      license = licenses.mit;
      maintainers = [ maintainers.sudosubin ];
      platforms = [ "x86_64-darwin" "aarch64-darwin" ];
    };
  };
}
