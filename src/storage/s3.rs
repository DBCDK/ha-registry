// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileCopyrightText: 2022 Zhaofeng Li and the Attic contributors
// SPDX-FileContributor: Christina Sørensen
// SPDX-FileContributor: Zhaofeng Li and the Attic contributors
//
// SPDX-License-Identifier: EUPL-1.2
// SPDX-License-Identifier: Apache-2.0

// TODO: Rewrite/Write out Zhaofeng Li attic code to simplify license
// https://github.com/zhaofengli/attic/blob/717cc95983cdc357bc347d70be20ced21f935843/server/src/storage/s3.rs

use std::error::Error;

use aws_sdk_s3::{
    config::Builder as S3ConfigBuilder,
    config::{Credentials, Region},
    Client,
};
use serde::{Deserialize, Serialize};

/// The S3 remote file storage backend.
#[derive(Debug)]
pub struct S3Backend {
    // FIXME: Will be used in the future
    #[allow(dead_code)]
    client: Client,
    // FIXME: Will be used in the future
    #[allow(dead_code)]
    config: S3StorageConfig,
}

/// S3 remote file storage configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct S3StorageConfig {
    /// The AWS region.
    region: String,

    /// The name of the bucket.
    bucket: String,

    /// Custom S3 endpoint.
    ///
    /// Set this if you are using an S3-compatible object storage (e.g., Minio).
    endpoint: Option<String>,

    /// S3 credentials.
    ///
    /// If not specified, it's read from the `AWS_ACCESS_KEY_ID` and
    /// `AWS_SECRET_ACCESS_KEY` environment variables.
    credentials: Option<S3CredentialsConfig>,
}

/// S3 credential configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct S3CredentialsConfig {
    /// Access key ID.
    access_key_id: String,

    /// Secret access key.
    secret_access_key: String,
}

impl Default for S3StorageConfig {
    fn default() -> Self {
        Self {
            region: "us-east-1".into(),
            bucket: "ha-registry".into(),
            endpoint: Some("https://s3.example.com".into()),
            credentials: S3CredentialsConfig::default().into(),
        }
    }
}

impl Default for S3CredentialsConfig {
    fn default() -> Self {
        Self {
            access_key_id: "access_key_id".into(),
            secret_access_key: "secret_access_key".into(),
        }
    }
}

impl S3Backend {
    pub async fn new(config: &S3StorageConfig) -> Result<Self, Box<dyn Error>> {
        let s3_config = Self::config_builder(config)
            .await?
            .region(Region::new(config.region.to_owned()))
            .build();

        Ok(Self {
            client: Client::from_conf(s3_config),
            config: config.clone(),
        })
    }

    async fn config_builder(config: &S3StorageConfig) -> Result<S3ConfigBuilder, Box<dyn Error>> {
        // FIXME: load_from_env deprecation warning from aws-sdk, should be fixed eventually
        #[allow(deprecated)]
        let shared_config = aws_config::load_from_env().await;
        let mut builder = S3ConfigBuilder::from(&shared_config);

        if let Some(credentials) = &config.credentials {
            builder = builder.credentials_provider(Credentials::new(
                &credentials.access_key_id,
                &credentials.secret_access_key,
                None,
                None,
                "s3",
            ));
        }

        if let Some(endpoint) = &config.endpoint {
            builder = builder.endpoint_url(endpoint).force_path_style(true);
        }

        Ok(builder)
    }
}
