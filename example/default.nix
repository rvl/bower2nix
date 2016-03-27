{ myWebApp ? { outPath = ./.; name = "myWebApp"; }
, pkgs ? import <nixpkgs> {}
}:

pkgs.stdenv.mkDerivation {
  name = "my-web-app-frontend";
  src = myWebApp;

  buildInputs = [ pkgs.nodePackages.gulp ];

  bowerComponents = pkgs.buildBowerComponents {
    name = "my-web-app";
    generated = ./bower-packages.nix;
    src = myWebApp;
  };

  buildPhase = ''
    # gulp build using copied in bower_components
    cp  --reflink=auto --no-preserve=mode -R $bowerComponents/bower_components .
    HOME=$PWD ${pkgs.nodePackages.gulp}/bin/gulp build
  '';

  installPhase = "mv gulpdist $out";
}
