#![allow(clippy::type_complexity)]

// SPDX-FileCopyrightText: 2023-2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use serde::{Deserialize, Serialize};
use std::fs::{self, write};
use std::io::Error;

use log::*;

use crate::storage::s3::S3StorageConfig;

/// Default path to configuraiton file
pub const CONFIG: &str = "config.yaml";

/// Default address for registry
const ADDR: &str = "0.0.0.0";

/// Default port for registry
const PORT: &str = "3000";

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Config {
    /// The address of the server
    #[serde(skip_serializing_if = "Option::is_none")]
    addr: Option<String>,

    /// The port of the server
    #[serde(skip_serializing_if = "Option::is_none")]
    port: Option<String>,

    /// The S3 storage configuration
    #[serde(skip_serializing_if = "Option::is_none")]
    s3: Option<S3StorageConfig>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            addr: Some(ADDR.into()),
            port: Some(PORT.into()),
            s3: Some(S3StorageConfig::default()),
        }
    }
}

impl Config {
    /// Loads the configuration toml from a path into the Config struct.
    #[inline]
    pub fn new(path: &str) -> Result<Self, Box<dyn std::error::Error>> {
        debug!("initializing new Config struct");
        let yaml = fs::read_to_string(path)?;

        debug!("deserialized yaml from config file");
        let config = serde_yaml::from_str(&yaml)?;

        Ok(config)
    }

    #[inline]
    pub fn load(path: &str) -> Self {
        trace!("path: {path:#?}");
        match Self::new(path) {
            Ok(config) => config,
            Err(_) => Config::default(),
        }
    }

    pub fn bind_addr(&self) -> std::net::SocketAddr {
        let socket_addr: String = format!(
            "{}:{}",
            self.addr.clone().unwrap_or(ADDR.to_string()),
            self.port.clone().unwrap_or(PORT.to_string())
        );

        debug!("socket_addr: {socket_addr:#?}");

        socket_addr
            .parse()
            .expect("failed to parse the bind address")
    }

    pub fn gen_example_config(path: &String) -> Result<(), Error> {
        let data =
            serde_yaml::to_string(&Config::default()).expect("failed to deserialize self to yaml");
        write(path, data)
    }
}
