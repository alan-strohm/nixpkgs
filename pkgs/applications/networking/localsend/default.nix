{ lib, stdenv, appimageTools, fetchurl, undmg }:

let
  pname = "localsend";
  version = "1.8.0";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/localsend/localsend/releases/download/v${version}/LocalSend-${version}.AppImage";
      hash = "sha256-Setxw0urfJCiHI+Ms+Igroi1CLCgB0H5BsV6RkxyBME=";
    };
    x86_64-darwin = fetchurl {
      url = "https://github.com/localsend/localsend/releases/download/v${version}/LocalSend-${version}.dmg";
      hash = "sha256-uVZ/ULhr8CiV/wL9Yaw6q2IYAHNqld606ADKab/EVlU=";
    };
  };
  src = srcs.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  appimageContents = appimageTools.extract { inherit pname version src; };

  linux = appimageTools.wrapType2 rec {
    inherit pname version src meta;

    extraPkgs = p: [ p.libepoxy ];

    extraInstallCommands = ''
      mv $out/bin/${pname}-${version} $out/bin/${pname}

      install -m 444 -D ${appimageContents}/org.localsend.localsend_app.desktop \
        $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Icon=application-vnd.appimage' 'Icon=${pname}' \
        --replace 'Exec=localsend_app' 'Exec=$out/bin/localsend'

      install -m 444 -D ${appimageContents}/application-vnd.appimage.svg \
        $out/share/icons/hicolor/scalable/apps/${pname}.svg
    '';
  };

  darwin = stdenv.mkDerivation {
    inherit pname version src meta;

    nativeBuildInputs = [ undmg ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r *.app $out/Applications
    '';
  };

  meta = with lib; {
    description = "An open source cross-platform alternative to AirDrop";
    homepage = "https://localsend.org/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.mit;
    maintainers = with maintainers; [ sikmir ];
    platforms = builtins.attrNames srcs;
  };
in
if stdenv.isDarwin
then darwin
else linux
