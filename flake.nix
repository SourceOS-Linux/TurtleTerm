{
  description = "TurtleTerm — AI agent terminal fabric for SourceOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        turtleScripts = [
          "sourceos-term" "turtle-term" "turtle-agentd" "turtle-agentctl"
          "turtle-agent-status" "turtle-tmux" "turtle-cloudfog"
          "turtle-superconscious" "turtle-agent-machine" "turtle-language"
          "turtle-session" "turtle-synapseiq" "synapseiq-lsp" "turtle-plan-view"
          "turtle-selftest" "turtle-runbook" "turtle-voice" "turtle-sync"
          "turtle-perf" "turtle-persona" "turtle-files" "turtle-bg" "turtle-dash"
          "turtle-pr" "turtle-issue" "turtle-hooks" "turtle-gitea" "turtle-ci"
          "turtle-review" "turtle-watch" "turtle-cost" "turtle-copilot"
          "turtle-gh" "turtle-env" "turtle-diagnose" "turtle-apply"
          "turtle-chain" "turtle-ai-chat"
        ];
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "turtleterm";
          version = "1.4.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.cargo pkgs.rustc pkgs.cmake pkgs.pkg-config pkgs.makeWrapper ];
          buildInputs = [
            pkgs.fontconfig pkgs.freetype pkgs.openssl pkgs.python3
            pkgs.xorg.libX11 pkgs.xorg.libxcb pkgs.libxkbcommon pkgs.zlib
          ];

          buildPhase = ''
            export CARGO_HOME=$TMPDIR/cargo
            cargo build --release --locked -p wezterm -p wezterm-gui -p wezterm-mux-server
          '';

          installPhase = ''
            mkdir -p $out/lib/turtleterm $out/bin $out/share/turtleterm/shell $out/etc/turtleterm
            install -Dm755 target/release/wezterm            $out/lib/turtleterm/wezterm
            install -Dm755 target/release/wezterm-gui         $out/lib/turtleterm/wezterm-gui
            install -Dm755 target/release/wezterm-mux-server  $out/lib/turtleterm/wezterm-mux-server

            for s in ${builtins.concatStringsSep " " turtleScripts}; do
              if [ -f assets/sourceos/bin/$s ]; then
                install -Dm755 assets/sourceos/bin/$s $out/bin/$s
                patchShebangs $out/bin/$s
              fi
            done

            if [ -f assets/sourceos/mcp/turtle-mcp-server ]; then
              install -Dm755 assets/sourceos/mcp/turtle-mcp-server $out/bin/turtle-mcp-server
              patchShebangs $out/bin/turtle-mcp-server
            fi

            for f in assets/sourceos/shell/*; do
              [ -f "$f" ] && install -Dm644 "$f" $out/share/turtleterm/shell/$(basename "$f") || true
            done

            [ -f assets/sourceos/turtleterm.lua ] && install -Dm644 assets/sourceos/turtleterm.lua $out/etc/turtleterm/turtleterm.lua || true

            makeWrapper $out/lib/turtleterm/wezterm-gui $out/bin/turtleterm \
              --set TURTLE_TERM_RUNTIME_DIR $out/lib/turtleterm \
              --set TURTLETERM_CONFIG $out/etc/turtleterm/turtleterm.lua
            makeWrapper $out/lib/turtleterm/wezterm-mux-server $out/bin/turtleterm-mux-server \
              --set TURTLE_TERM_RUNTIME_DIR $out/lib/turtleterm
          '';

          meta = with pkgs.lib; {
            description = "AI agent terminal fabric for SourceOS — WezTerm + 38 agent commands";
            homepage = "https://github.com/SourceOS-Linux/TurtleTerm";
            license = licenses.mit;
            platforms = platforms.unix;
            mainProgram = "turtleterm";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.cargo pkgs.rustc pkgs.cmake pkgs.pkg-config pkgs.python3 ];
        };
      });
}
