// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use std::sync::Arc;

use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

/// The state of the server.
///
/// - Healthy: everything is working
/// - Degraded: something is broken, but ha-registry can still run
/// - Unhealthy: ha-registry is not working
///
/// May be expanded later.
#[derive(Serialize, Deserialize, Debug, Default)]
pub enum ServerState {
    #[default]
    Healthy,
    Degraded,
    Unhealthy,
}

/// Represents status of server, exposed over a status endpoint. Used to see the
/// current state of ha-registry.
#[derive(Serialize, Deserialize, Debug)]
pub struct ServerStatus {
    pub server_state: ServerState,
}

impl ServerStatus {
    /// Creates a new server status struct wrapped in an `Arc<RwLock<Self>>`,
    /// with default state.
    pub fn new() -> Arc<RwLock<Self>> {
        Arc::new(RwLock::new(Self {
            server_state: ServerState::default(),
        }))
    }
}
