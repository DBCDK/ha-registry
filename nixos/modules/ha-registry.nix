# SPDX-FileCopyrightText: 2024 Christina Sørensen
# SPDX-FileContributor: Christina Sørensen
#
# SPDX-License-Identifier: AGPL-3.0-only
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ha-registry;

  addr = "localhost";

  port = 3000;

  settingsFormat = pkgs.formats.json {};
in {
  options.services.ha-registry = {
    enable = mkEnableOption "ha-registry";

    package = mkPackageOption pkgs "ha-registry" {};

    openFirewall = mkEnableOption "opening the default ports in the firewall for ha-registry";

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          addr = mkOption {
            type = with types; nullOr str;
            default = addr;
            description = ''
              Address to listen on.
            '';
          };
          port = mkOption {
            type = types.port;
            default = port;
            example = 3456;
            description = ''
              Port to listen on.
            '';
          };
          description = ''
            ha-registry configuration as yaml.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.ha-registry = {
      enable = true;
      description = "ha-registry";
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];

      serviceConfig = {
        Restart = "always";
        ExecStart = let
          args = [];
        in "${cfg.package}/bin/ha-registry ${concatStringsSep " " args}";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.settings.port];
    };

    meta.maintainers = [cafkafk];
  };
}
