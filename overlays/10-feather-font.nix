self: super: with super; {
  feather-font =
    let
      version = "1.0";
      pname = "feather-font";
    in
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      # Security consideration: This uses a tag reference which could be moved
      # For maximum security, consider switching to fetchFromGitHub with commit hash:
      # rev = "b7138c5a9e3fa9fb9de3722d818af9f53660393b"; # v1.0
      src = fetchzip {
        url = "https://github.com/dustinlyons/feather-font/archive/refs/tags/${version}.zip";
        sha256 = "sha256-Zsz8/qn7XAG6BVp4XdqooEqioFRV7bLH0bQkHZvFbsg=";
      };

      buildInputs = [ unzip ];
      phases = [ "unpackPhase" "installPhase" ];

      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp $src/feather.ttf $out/share/fonts/truetype/
      '';

      meta = with lib; {
        homepage = "https://www.feathericons.com/";
        description = "Set of font icons from the open source collection Feather Icons";
        license = licenses.mit;
        maintainers = [ maintainers.dlyons ];
        platforms = platforms.all;
      };
    };
}
