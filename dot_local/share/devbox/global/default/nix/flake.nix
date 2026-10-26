{
  description = "Version-pinned general CLI packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/687f05a9184cad4eaf905c48b63649e3a86f5433";

  outputs = { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        mo = pkgs.callPackage ./packages/mo.nix { };
        stripe = pkgs.callPackage ./packages/stripe.nix { };
        apm = pkgs.callPackage ./packages/apm.nix { };
        gcloud = pkgs.callPackage ./packages/gcloud.nix { };
      };
    };
}
