// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use serde::{Deserialize, Serialize};

/// The state of the server.
///
/// - Healthy: everything is working
/// - Degraded: something is broken, but ha-registry can still run
/// - Unhealthy: ha-registry is not working
///
/// May be expanded later.
#[derive(Serialize, Deserialize)]
pub enum ServerState {
    Healthy,
    Degraded,
    Unhealthy,
}

/// Status struct exposed over status endpoint. Used to see the current state of
/// ha-registry.
#[derive(Serialize, Deserialize)]
pub struct Status {
    pub server_state: ServerState,
}
