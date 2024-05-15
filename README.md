<!--
SPDX-FileCopyrightText: 2024 Christina Sørensen
SPDX-FileContributor: Christina Sørensen

SPDX-License-Identifier: AGPL-3.0-only
-->

<div align="center">

# HA-registry
> Important
>
> HA-registry is in an early stage of development, and not recommened for
> production usage.

> Important
> 
> HA-registry is experimental, and is subject to API changes until stabilized.

</div>

HA-registry, is a highly available, blazingly fast™ OCI container distribution
service, written in rust, and leveraging an S3 backend for blob storage and a
postgresql database for distributed locking. It's goal is to support being both
pull and push available under both update rollout and garbage collection for 
a n>=2 deployment.

It's designed with automation of garbage collection in mind, and hopes to
replace enterprise registry solutions like artifactory, by implementing features
like virtual repositories and promotion based garbage collection

Another goal is to be able to standup a database by walking the S3 storage,
ensuring the database only needs to be consistent during runtime.

HA-registry is licensed under AGPLv3, without a CLA, and seeks to stay REUSE
compliant. We also enforce conventional commits, and seek to have a strong
semver culture.

Other technologies leveraged in the project includes Axum, Tokio, and Nix for
development shells, packaging, and NixOS VM tests.

### OCI API Compliance
#### Endpoints

| ID      | Method         | API Endpoint                                                   | Success     | Failure           | Implemented |
| ------- | -------------- | -------------------------------------------------------------- | ----------- | ----------------- | ----------- |
| end-1   | `GET`          | `/v2/`                                                         | `200`       | `404`/`401`       |             |
| end-2   | `GET` / `HEAD` | `/v2/<name>/blobs/<digest>`                                    | `200`       | `404`             |             |
| end-3   | `GET` / `HEAD` | `/v2/<name>/manifests/<reference>`                             | `200`       | `404`             |             |
| end-4a  | `POST`         | `/v2/<name>/blobs/uploads/`                                    | `202`       | `404`             |             |
| end-4b  | `POST`         | `/v2/<name>/blobs/uploads/?digest=<digest>`                    | `201`/`202` | `404`/`400`       |             |
| end-5   | `PATCH`        | `/v2/<name>/blobs/uploads/<reference>`                         | `202`       | `404`/`416`       |             |
| end-6   | `PUT`          | `/v2/<name>/blobs/uploads/<reference>?digest=<digest>`         | `201`       | `404`/`400`       |             |
| end-7   | `PUT`          | `/v2/<name>/manifests/<reference>`                             | `201`       | `404`             |             |
| end-8a  | `GET`          | `/v2/<name>/tags/list`                                         | `200`       | `404`             |             |
| end-8b  | `GET`          | `/v2/<name>/tags/list?n=<integer>&last=<tagname>`              | `200`       | `404`             |             |
| end-9   | `DELETE`       | `/v2/<name>/manifests/<reference>`                             | `202`       | `404`/`400`/`405` |             |
| end-10  | `DELETE`       | `/v2/<name>/blobs/<digest>`                                    | `202`       | `404`/`405`       |             |
| end-11  | `POST`         | `/v2/<name>/blobs/uploads/?mount=<digest>&from=<other_name>`   | `201`       | `404`             |             |
| end-12a | `GET`          | `/v2/<name>/referrers/<digest>`                                | `200`       | `404`/`400`       |             |
| end-12b | `GET`          | `/v2/<name>/referrers/<digest>?artifactType=<artifactType>`    | `200`       | `404`/`400`       |             |
| end-13  | `GET`          | `/v2/<name>/blobs/uploads/<reference>`                         | `204`       | `404`             |             |

# See Also
- CNCF Distribution: https://distribution.github.io/distribution/
- OCI Distribution Spec: https://github.com/opencontainers/distribution-spec/blob/main/spec.md
