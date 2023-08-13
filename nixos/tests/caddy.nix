import ./make-test-python.nix ({ pkgs, ... }: {
  name = "caddy";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ xfix Br1ght0ne ];
  };

  nodes = {
    webserver = { pkgs, lib, ... }: {
      services.caddy.enable = true;
      services.caddy.extraConfig = ''
        http://localhost {
          encode gzip

          file_server
          root * ${
            pkgs.runCommand "testdir" {} ''
              mkdir "$out"
              echo hello world > "$out/example.html"
            ''
          }
        }
      '';
      services.caddy.enableReload = true;

      specialisation.config-reload.configuration = {
        services.caddy.extraConfig = ''
          http://localhost:8080 {
          }
        '';
      };
      specialisation.multiple-configs.configuration = {
        services.caddy.virtualHosts = {
          "http://localhost:8080" = { };
          "http://localhost:8081" = { };
        };
      };
    };
  };

  testScript = { nodes, ... }:
    let
      justReloadSystem = "${nodes.webserver.system.build.toplevel}/specialisation/config-reload";
      multipleConfigs = "${nodes.webserver.system.build.toplevel}/specialisation/multiple-configs";
    in
    ''
      url = "http://localhost/example.html"
      webserver.wait_for_unit("caddy")
      webserver.wait_for_open_port(80)


      with subtest("config is reloaded on nixos-rebuild switch"):
          webserver.succeed(
              "${justReloadSystem}/bin/switch-to-configuration test >&2"
          )
          webserver.wait_for_open_port(8080)
          webserver.fail("journalctl -u caddy | grep -q -i stopped")
          webserver.succeed("journalctl -u caddy | grep -q -i reloaded")

      with subtest("multiple configs are correctly merged"):
          webserver.succeed(
              "${multipleConfigs}/bin/switch-to-configuration test >&2"
          )
          webserver.wait_for_open_port(8080)
          webserver.wait_for_open_port(8081)
    '';
})
