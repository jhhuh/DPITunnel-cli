{

  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-23.11;

  inputs.cpp-httplib.url = github:yhirose/cpp-httplib;
  inputs.cpp-httplib.flake = false;

  # inputs.dnslib.url = github:mnezerka/dnslib;
  inputs.dnslib.url = github:takifujis/dnslib/develop;
  inputs.dnslib.flake = false;

  outputs = inputs:
    let

      system = "x86_64-linux";

      pkgs = import inputs.nixpkgs { inherit system; overlays = [ overlay ]; };


      mk-cpp-httplib = { stdenv, meson, ninja, openssl, brotli, zlib, pkg-config }:
        stdenv.mkDerivation {
          name = "cpp-httplib";
          src = inputs.cpp-httplib;
          nativeBuildInputs = [ meson ninja pkg-config ];
          buildInputs = [ openssl brotli zlib ];
          mesonFlags = ["-Dcpp-httplib_compile=true"];
        };

      mk-dnslib = { stdenv, cmake, pkg-config, openssl }:
        stdenv.mkDerivation {
          name = "dnslib";
          #src = ./dnslib;
          src = inputs.dnslib;
          nativeBuildInputs = [ cmake pkg-config ];
          env.cmakeDir = "../src/";
          env.NIX_CFLAGS_COMPILE = "-Wno-error=unused-variable";
          installPhase = ''
            mkdir -p $out/lib/pkgconfig
            mkdir -p $out/include/dnslib

            cp ../src/*.h $out/include/dnslib/
            cp ./libdnslib.a $out/lib/

            cat >> $out/lib/pkgconfig/dnslib.pc << EOF
            Name: dnslib
            Description: dnslib
            Version: 0.0.1
            Libs: -L$out/lib/ -ldnslib
            Cflags: -I$out/include
            EOF
          '';
        };

      mk-DPITunnel-cli = { stdenv, cmake, pkg-config, meson, libnl, openssl, cpp-httplib, dnslib }:
        stdenv.mkDerivation {
          name = "DPITunnel-cli";
          src = ./.;
          nativeBuildInputs = [ cmake pkg-config meson ];
          buildInputs = [
            libnl
            openssl
            cpp-httplib
            dnslib
          ];
          installPhase = ''
            mkdir -p $out/bin
            cp ./DPITunnel-cli-exec $out/bin/DPITunnel-cli
          '';
          #cmakeFlags = [ "-DSTATIC_BINARY=true" "-DOPENSSL_ROOT_DIR=${openssl.out}" ];
        };

      overlay = self: super:
        {
          DPITunnel-cli = self.callPackage mk-DPITunnel-cli {};
          cpp-httplib = self.callPackage mk-cpp-httplib {};
          dnslib = self.callPackage mk-dnslib {};
        };

    in
      {

        inherit pkgs;

        packages.${system}.default = pkgs.DPITunnel-cli;

        devShells.${system}.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ cmake pkg-config meson ninja python3 ];
          buildInputs = with pkgs; [
            libnl
            openssl
            brotli
            zlib
            cpp-httplib
            dnslib
          ];
        };
      };


}
