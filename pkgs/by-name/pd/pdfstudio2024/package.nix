{
  buildFHSEnv
, stdenv
, lib
, dpkg
, makeDesktopItem
, copyDesktopItems
, autoPatchelfHook
, sane-backends
, cups
, fetchurl
, jdk17
}:
let
  year = "2024";
  version = "${year}.0.0";
  pname = "pdfstudio${year}";
  program = "pdfstudio";
  dot2dash = str: builtins.replaceStrings [ "." ] [ "_" ] str;
  thisPackage = stdenv.mkDerivation rec {
    inherit pname version;
    desktopName = "PDF Studio ${year}";
    src = fetchurl {
      url = "https://download.qoppa.com/pdfstudio/v${year}/PDFStudio_v${dot2dash version}_linux64.deb";
      sha256 = "sha256-9TMSKtBE0+T7wRnBgtUjRr/JUmCaYdyD/7y0ML37wCM=";
    };

    strictDeps = true;

    buildInputs = [
      sane-backends #for libsane.so.1
    ] ++ extraBuildInputs;

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      copyDesktopItems
    ];

    extraBuildInputs = [
      (lib.getLib stdenv.cc.cc)  # for libstdc++.so.6 and libgomp.so.1
    ];

    jdk = jdk17;

    desktopItems = [
      (makeDesktopItem {
        name = "${pname}";
        desktopName = "PDF Studio ${year}";
        genericName = "View and edit PDF files";
        exec = "${pname} %f";
        icon = "${pname}";
        comment = "Views and edits PDF files";
        mimeTypes = [ "application/pdf" ];
        categories = [ "Office" ];
      })
    ];

    unpackCmd = "dpkg-deb -x $src ./pdfstudio-${version}";
    dontBuild = true;

    postPatch = ''
      substituteInPlace opt/${program}${year}/${program}${year} --replace "# INSTALL4J_JAVA_HOME_OVERRIDE=" "INSTALL4J_JAVA_HOME_OVERRIDE=${jdk.out}"
      substituteInPlace opt/${program}${year}/updater --replace "# INSTALL4J_JAVA_HOME_OVERRIDE=" "INSTALL4J_JAVA_HOME_OVERRIDE=${jdk.out}"
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,share/pixmaps}
      rm -rf opt/${program}${year}/jre
      cp -r opt/${program}${year} $out/share/
      ln -s $out/share/${program}${year}/.install4j/${program}${year}.png  $out/share/pixmaps/${pname}.png
      ln -s $out/share/${program}${year}/${program}${year} $out/bin/

      runHook postInstall
    '';
  };

in
# Package with cups in FHS sandbox, because JAVA bin expects "/usr/bin/lpr" for printing.
buildFHSEnv {
  #inherit pname;
  name = pname;
  targetPkgs = pkgs: [
    cups
    thisPackage
  ];
  runScript = "${program}${year}";

  # link desktop item and icon into FHS user environment
  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/pixmaps"
    ln -s ${thisPackage}/share/applications/*.desktop "$out/share/applications/"
    ln -s ${thisPackage}/share/pixmaps/*.png "$out/share/pixmaps/"
  '';

  meta = with lib; {
    broken = false;
    homepage = "https://www.qoppa.com/${pname}/";
    description = "An easy to use, full-featured PDF editing software";
    longDescription = ''
    PDF Studio is an easy to use, full-featured PDF editing software. This is the standard/pro edition, which requires a license. For the free PDF Studio Viewer see the package pdfstudioviewer.
  '';
    sourceProvenance = with sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    license = licenses.unfree;
    platforms = platforms.linux;
    mainProgram = pname;
    maintainers = [ maintainers.pwoelfel ];
  };
}
