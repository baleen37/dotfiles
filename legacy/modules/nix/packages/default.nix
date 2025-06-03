{ inputs, ... }:
{
  default = [
    (final: prev: {
      hammerspoon = final.callPackage ./hammerspoon {};
      homerow = final.callPackage ./homerow {};
      # 필요시 다른 패키지를 여기에 추가
    })
  ];
}
