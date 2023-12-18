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

      overlay = self: super:
        {
          DPITunnel-cli = self.callPackage ./. {};
        };

      cpp-httplib = pkgs.stdenv.mkDerivation {
        name = "cpp-httplib";
        src = inputs.cpp-httplib;
        nativeBuildInputs = with pkgs; [ meson ninja pkg-config ];
        buildInputs = with pkgs; [ openssl brotli zlib ];
        mesonFlags = ["-D cpp-httplib_compile=true"];
      };

      dnslib = pkgs.stdenv.mkDerivation {
        name = "dnslib";
        #src = ./dnslib;
        src = inputs.dnslib;
        nativeBuildInputs = with pkgs; [ cmake pkg-config ];
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

    in
      {

        inherit inputs cpp-httplib dnslib;

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
