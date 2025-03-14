pkgs: {
  oci-cli = pkgs.callPackage ./oci-cli { };
  # We temporarily need to pin because later versions break Go
  wasm-tools = pkgs.callPackage ./wasm-tools { };
}
