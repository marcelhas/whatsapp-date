# Thanks to <https://ertt.ca/nix/shell-scripts/> for his simple introduction!
{
  description = "Set modified date on whatsapp images.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mainScriptName = "whatsapp-date";
        testScriptName = "test";
        buildInputs = with pkgs; [ ];
        mainScript = (pkgs.writeScriptBin mainScriptName
          (builtins.readFile ./whatsapp-date.sh)).overrideAttrs (old: {
            buildCommand = ''
              ${old.buildCommand}
               patchShebangs $out'';
          });
        testScript = (pkgs.writeScriptBin testScriptName
          (builtins.readFile ./test.sh)).overrideAttrs (old: {
            buildCommand = ''
              ${old.buildCommand}
               patchShebangs $out'';
          });

      in rec {
        defaultPackage = packages.whatsapp-date;
        # Main script.
        packages.whatsapp-date = pkgs.symlinkJoin {
          name = mainScriptName;
          paths = [ mainScript ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild =
            "wrapProgram $out/bin/${mainScriptName} --prefix PATH : $out/bin";
        };
        # Tests.
        packages.test = pkgs.symlinkJoin {
          name = testScriptName;
          paths = [ testScript ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild =
            "wrapProgram $out/bin/${testScriptName} --prefix PATH : $out/bin";
        };
        # Dev environment.
        devShell = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = with pkgs; [ nixfmt ];
        };
      });
}
