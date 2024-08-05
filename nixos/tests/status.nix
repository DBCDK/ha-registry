# SPDX-FileCopyrightText: 2024 Christina Sørensen
# SPDX-FileContributor: Christina Sørensen
#
# SPDX-License-Identifier: EUPL-1.2
{ lib
, nixosTest
, packages
, ...
}:
nixosTest {
  name = "ha-registry status test";

  nodes =
    let
      minioAccessKey = "legit";
      minioSecretKey = "111-1111111";
      minio = _: {
        services.minio = {
          enable = true;
          rootCredentialsFile = "/etc/minio.env";
        };

        # For testing only - Don't actually do this
        environment.etc."minio.env".text = ''
          MINIO_ROOT_USER=${minioAccessKey}
          MINIO_ROOT_PASSWORD=${minioSecretKey}
        '';

        networking.firewall.allowedTCPPorts = [ 9000 ];
      };
      postgres = _: {
        systemd.services.postgresql.postStart = lib.mkAfter ''
          $PSQL -tAc 'ALTER DATABASE "registry" OWNER TO "registry"'
        '';

        services.postgresql = {
          enable = true;
          ensureDatabases = [ "registry" ];
          ensureUsers = [
            {
              name = "registry";
            }

            # For testing only - Don't actually do this
            {
              name = "root";
              ensureClauses = {
                superuser = true;
              };
            }
          ];
        };
      };
    in
    {
      inherit minio postgres;

      haregistry = { ... }: {
        imports = [
          ../modules/ha-registry.nix
        ];

        services.etcd = {
          enable = true;

          openFirewall = true;
        };

        systemd.services.ha-registry.environment = {
          RUST_BACKTRACE = "full";
          RUST_LOG = "trace";
        };

        services.ha-registry = {
          enable = true;
          package = packages.default;

          openFirewall = true;

          # services.atticd.settings = {
          #   database.url = "postgresql:///registry?host=/run/postgresql";
          # };

          settings = {
            addr = "0.0.0.0";
            port = 3000;
            s3 = {
              region = "us-east-1";
              bucket = "registry";
              endpoint = "http://minio:9000";
              credentials = {
                access_key_id = minioAccessKey;
                secret_access_key = minioSecretKey;
              };
            };
          };
        };
      };

      client1 = _: { };
    };

  testScript = ''
    start_all()

    minio.wait_for_unit("minio.service")
    postgres.wait_for_unit("postgresql.service")

    haregistry.wait_for_unit("ha-registry.service")
    haregistry.wait_for_open_port(3000)

    haregistry.wait_until_succeeds("curl haregistry:3000/ha/v1/status", timeout=120)

    client1.wait_until_succeeds("curl haregistry:3000/ha/v1/status", timeout=120)
    client1.succeed("curl haregistry:3000/ha/v1/status")
    client1.fail("curl --fail haregistry:3000/ha")
    client1.fail("curl --fail haregistry:3000/ha/")
    client1.fail("curl --fail haregistry:3000/ha/v1")
    client1.fail("curl --fail haregistry:3000/ha/v1/")

    client1.succeed("curl haregistry:3000/v2/")

    minio.succeed("mkdir /var/lib/minio/data/registry")
    minio.succeed("chown minio: /var/lib/minio/data/registry")
    client1.wait_until_succeeds("curl http://minio:9000", timeout=20)

    from pathlib import Path
    import os

    schema = postgres.succeed("pg_dump --schema-only registry")

    schema_path = Path(os.environ.get("out", os.getcwd())) / "schema.sql"
    with open(schema_path, 'w') as f:
      f.write(schema)
  '';
}
