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

      services.etcd = {
        enable = true;

        openFirewall = true;
      };

      services.ha-registry = {
        enable = true;
        package = packages.default;

        openFirewall = true;
      };
    };

    client1 = _: {
    };
  };

  testScript = ''
    start_all()

    haregistry.wait_for_open_port(3000)
    haregistry.wait_for_unit("ha-registry.service")

    client1.succeed("curl haregistry:3000/ha/v1/status")
    client1.fail("curl --fail haregistry:3000/ha")
    client1.fail("curl --fail haregistry:3000/ha/")
    client1.fail("curl --fail haregistry:3000/ha/v1")
    client1.fail("curl --fail haregistry:3000/ha/v1/")
  '';
}
