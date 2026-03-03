{ rev }:
let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib stdenv apple-sdk_11;
  zlib = pkgs.zlib.override { static = true; shared = false; };
  openssl = pkgs.openssl.override { static = true; };
in
# Based on https://github.com/NixOS/nixpkgs/blob/af51e23ce535b1bfa8484021ff3913d876e09082/pkgs/development/libraries/tdlib/default.nix
stdenv.mkDerivation {
  pname = "tdlib";
  version = "0.0";

  src = builtins.fetchTarball "https://github.com/tdlib/td/archive/${rev}.tar.gz";

  buildInputs = [ openssl zlib apple-sdk_11 ];
  nativeBuildInputs = with pkgs; [ cmake gperf ];
    # cmake -DCMAKE_BUILD_TYPE=Release -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl/ -DCMAKE_INSTALL_PREFIX:PATH=../tdlib ..
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DOPENSSL_USE_STATIC_LIBS=TRUE"
    "-DZLIB_USE_STATIC_LIBS=TRUE"
    "-DCMAKE_INSTALL_PREFIX:PATH=../tdlib .."
  ];

  buildPhase = ''
    cmake --build . --target install -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/
    cp -R . "$out"/
    runHook postInstall
  '';

  # https://github.com/tdlib/td/issues/1974
  postPatch = ''
    substituteInPlace CMake/GeneratePkgConfig.cmake \
      --replace 'function(generate_pkgconfig' \
                'include(GNUInstallDirs)
                 function(generate_pkgconfig' \
      --replace '\$'{prefix}/'$'{CMAKE_INSTALL_LIBDIR} '$'{CMAKE_INSTALL_FULL_LIBDIR} \
      --replace '\$'{prefix}/'$'{CMAKE_INSTALL_INCLUDEDIR} '$'{CMAKE_INSTALL_FULL_INCLUDEDIR}
  '' + lib.optionalString (stdenv.isDarwin && stdenv.isAarch64) ''
    sed -i "/vptr/d" test/CMakeLists.txt
  '';
}
