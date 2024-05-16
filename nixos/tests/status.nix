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
    s3 = let
      s3_port = 3900;
      rpc_port = 3901;
      admin_api_port = 3903;
    in
      {pkgs, ...}: {
        users = {
          groups.garage = {};

          users.garage = {
            isSystemUser = true;
            createHome = false;
            group = "garage";
          };
        };

        services = {
          garage = {
            enable = true;
            package = pkgs.garage;

            settings = {
              #metadata_dir = "/srv/storage/garage/meta";
              #data_dir = "/srv/storage/garage/data";
              #metadata_fsync = false; # synchronous mode for the database engine

              db_engine = "lmdb";
              replication_mode = "none";
              compression_level = -1;

              # For inter-node comms
              rpc_bind_addr = "[::]:${builtins.toString rpc_port}";
              rpc_secret = "4425f5c26c5e11581d3223904324dcb5b5d5dfb14e5e7f35e38c595424f5f1e6";
              # rpc_public_addr = "127.0.0.1:3901";

              # Standard S3 api endpoint
              s3_api = {
                s3_region = "helios";
                api_bind_addr = "[::]:${builtins.toString s3_port}";
              };

              # Admin api endpoint
              admin = {
                api_bind_addr = "[::]:${builtins.toString admin_api_port}";
              };
            };
          };
        };
      };

    db = _: {
      services.postgresql = {
        enable = true;
      };
    };

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

        settings = {
          s3 = {
            region = "us-east-1";
            bucket = "ha-registry";
            endpoint = "endpoint";
            credentials = {
              access_key_id = "stuff";
              secret_access_key = "stuff";
            };
          };
        };
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
