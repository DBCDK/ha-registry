// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use crate::data::status::{Status, ServerState};
use axum::{Json, http::StatusCode};

const TEST_STATUS: Status = Status { server_state: ServerState::Healthy };

/// Handler for returning the server status.
pub async fn status() -> Result<Json<Status>, StatusCode> {
    Ok(Json(TEST_STATUS))
}
// pub async fn status() -> StatusCode {
//     StatusCode::OK
// }
