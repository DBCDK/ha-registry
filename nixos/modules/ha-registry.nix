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

  addr = "127.0.0.1";

  port = 3000;

  settingsFormat = pkgs.formats.yaml {};
in {
  options.services.ha-registry = {
    enable = mkEnableOption "ha-registry";

    package = mkPackageOption pkgs "ha-registry" {};

    openFirewall = mkEnableOption "opening the default ports in the firewall for ha-registry";

    settings = mkOption {
      description = ''
        ha-registry configuration as yaml.
      '';
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

      environment = {
        # FIXME: consider doing this directly in aws-sdk it may have
        # implications for direct AWS usage thou
        AWS_EC2_METADATA_DISABLED = "true";
      };

      serviceConfig = {
        Restart = "always";
        ExecStart = let
          args = [];
        in "${cfg.package}/bin/ha-registry ${concatStringsSep " " args} --config ${settingsFormat.generate "registry-config.yaml" cfg.settings}";
        # Ensure registry isn't considered started before listening for
        # connections
        Type = "notify";
        NotifyAccess = "main";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.settings.port];
    };

    meta.maintainers = [cafkafk];
  };
}
