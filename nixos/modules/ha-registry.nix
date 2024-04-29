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
  port = 3000;
in {
  options.services.ha-registry = {
    enable = mkEnableOption "ha-registry";

    package = mkPackageOption pkgs "ha-registry" {};

    openFirewall = mkEnableOption "opening the default ports in the firewall for ha-registry";
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
      allowedTCPPorts = [port];
    };

    meta.maintainers = [cafkafk];
  };
}
