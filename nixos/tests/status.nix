# SPDX-FileCopyrightText: 2024 Christina Sørensen
# SPDX-FileContributor: Christina Sørensen
#
# SPDX-License-Identifier: AGPL-3.0-only
{
  nixosTest,
  packages,
  ...
}:
nixosTest {
  name = "ha-registry status test";

  nodes = {
    haregistry = {...}: {
      imports = [
        ../modules/ha-registry.nix
      ];
      services.ha-registry = {
        enable = true;
        package = packages.default;
      };
    };
  };

  testScript = ''
    start_all()

    haregistry.wait_for_open_port(3000)
    haregistry.wait_for_unit("ha-registry.service")
  '';
}
